module Api
  module V1
    class ZealyWebhookController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!

      def webhook
        # Add CORS headers
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, User-Agent'
        response.headers['Access-Control-Max-Age'] = '86400' # 24 hours

        # Gérer les requêtes OPTIONS pour les tests
        if request.method == 'OPTIONS'
          return render json: { status: 'ok' }, status: :ok
        end

        Rails.logger.info "🔵 [ZEALY WEBHOOK] Début du traitement"
        Rails.logger.info "🔵 [ZEALY WEBHOOK] Méthode: #{request.method}"
        Rails.logger.info "🔵 [ZEALY WEBHOOK] Headers: #{request.headers.to_h.select { |k,v| k.start_with?('HTTP_') }}"

        begin
          # Vérification des headers
          unless request.headers['User-Agent'] == 'Zealy-Webhook'
            Rails.logger.error "❌ [ZEALY WEBHOOK] User-Agent invalide"
            return render json: { error: "Invalid User-Agent" }, status: :unauthorized
          end

          raw_payload = request.body.read
          Rails.logger.info "📥 [ZEALY WEBHOOK] Payload reçu: #{raw_payload}"

          payload = JSON.parse(raw_payload, symbolize_names: true)
          Rails.logger.info "🔍 [ZEALY WEBHOOK] Payload parsé: #{payload.inspect}"

          # Vérification du secret selon le type d'événement
          expected_secret = case payload[:type]
          when 'JOINED_COMMUNITY', 'LEFT_COMMUNITY'
            ENV['ZEALY_WEBHOOK_COMMUNITY_SECRET']
          else
            ENV['ZEALY_WEBHOOK_SECRET']
          end

          unless payload[:secret] == expected_secret
            Rails.logger.error "❌ [ZEALY WEBHOOK] Secret invalide pour l'événement #{payload[:type]}"
            return render json: { error: "Invalid secret" }, status: :unauthorized
          end

          Rails.logger.info "✅ [ZEALY WEBHOOK] Secret validé"
          Rails.logger.info "🎯 [ZEALY WEBHOOK] Event: #{payload[:type]} - ID: #{payload[:id]}"

          # Traitement de l'événement
          case payload[:type]
          when 'JOINED_COMMUNITY'
            handle_joined_community(payload[:data])
          when 'LEFT_COMMUNITY'
            handle_left_community(payload[:data])
          when 'QUEST_SUCCEEDED'
            handle_quest_succeeded(payload[:data])
          when 'QUEST_CLAIMED'
            handle_quest_claimed(payload[:data])
          when 'QUEST_FAILED'
            handle_quest_failed(payload[:data])
          when 'QUEST_CLAIM_STATUS_UPDATED'
            handle_quest_claim_status_updated(payload[:data])
          when 'SPRINT_STARTED'
            handle_sprint_started(payload[:data])
          when 'SPRINT_ENDED'
            handle_sprint_ended(payload[:data])
          when 'USER_BANNED'
            handle_user_banned(payload[:data])
          else
            Rails.logger.info "⚠️ [ZEALY WEBHOOK] Type d'événement non géré: #{payload[:type]}"
          end

          # Retourner 200 pour confirmer la réception
          Rails.logger.info "🟢 [ZEALY WEBHOOK] Traitement terminé avec succès"
          render json: { received: true }, status: :ok
        rescue JSON::ParserError => e
          Rails.logger.error "❌ [ZEALY WEBHOOK] Erreur JSON: #{e.message}"
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "❌ [ZEALY WEBHOOK] Erreur inattendue: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      private

      def handle_joined_community(data)
        Rails.logger.info "🎉 [ZEALY WEBHOOK] Traitement JOINED_COMMUNITY"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        quest = Quest.find_by(quest_id: 'zealy_connect')
        return unless quest

        # Créer ou mettre à jour la complétion de la quête
        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        # Marquer la quête comme complétée et non complétable
        completion.progress = quest.progress_required
        completion.completable = false

        if completion.save
          # Ajouter l'XP immédiatement
          current_xp = user.experience || 0
          user.update!(experience: current_xp + quest.xp_reward)
          Rails.logger.info "🌟 [ZEALY WEBHOOK] XP ajoutée: +#{quest.xp_reward}"
          Rails.logger.info "✅ [ZEALY WEBHOOK] Quête Zealy marquée comme complétée"
        else
          Rails.logger.error "❌ [ZEALY WEBHOOK] Erreur lors de la mise à jour de la quête: #{completion.errors.full_messages}"
        end
      end

      def handle_left_community(data)
        Rails.logger.info "👋 [ZEALY WEBHOOK] Traitement LEFT_COMMUNITY"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        # Marquer l'utilisateur comme déconnecté de Zealy
        user.update!(zealy_user_id: nil)
      end

      def handle_quest_succeeded(data)
        Rails.logger.info "✨ [ZEALY WEBHOOK] Traitement QUEST_SUCCEEDED"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        quest = Quest.find_by(zealy_quest_id: data[:quest][:id])
        return unless quest

        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        # Marquer la quête comme complétée et non complétable immédiatement
        completion.progress = quest.progress_required
        completion.completable = false

        if completion.save
          # Ajouter l'XP immédiatement
          current_xp = user.experience || 0
          user.update!(experience: current_xp + quest.xp_reward)
          Rails.logger.info "🌟 [ZEALY WEBHOOK] XP ajoutée: +#{quest.xp_reward}"
          Rails.logger.info "✅ [ZEALY WEBHOOK] Quête marquée comme complétée et XP attribuée"
        else
          Rails.logger.error "❌ [ZEALY WEBHOOK] Erreur lors de la mise à jour de la quête: #{completion.errors.full_messages}"
        end
      end

      def handle_quest_claimed(data)
        Rails.logger.info "🎯 [ZEALY WEBHOOK] Traitement QUEST_CLAIMED"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        quest = Quest.find_by(zealy_quest_id: data[:quest][:id])
        return unless quest

        # Vérifier si la quête n'a pas déjà été complétée
        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        unless completion.completed?
          completion.progress = quest.progress_required
          completion.completable = false
          if completion.save
            # Ajouter l'XP si la quête n'était pas déjà complétée
            current_xp = user.experience || 0
            user.update!(experience: current_xp + quest.xp_reward)
            Rails.logger.info "🌟 [ZEALY WEBHOOK] XP ajoutée: +#{quest.xp_reward}"
          end
        end
      end

      def handle_quest_failed(data)
        Rails.logger.info "❌ [ZEALY WEBHOOK] Traitement QUEST_FAILED"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        quest = Quest.find_by(zealy_quest_id: data[:quest][:id])
        return unless quest

        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        completion.progress = 0
        completion.completable = false
        completion.save
      end

      def handle_quest_claim_status_updated(data)
        Rails.logger.info "🔄 [ZEALY WEBHOOK] Traitement QUEST_CLAIM_STATUS_UPDATED"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        quest = Quest.find_by(zealy_quest_id: data[:quest][:id])
        return unless quest

        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        case data[:status]
        when 'success'
          completion.progress = quest.progress_required
          completion.completable = false
          if completion.save && !completion.completed?
            current_xp = user.experience || 0
            user.update!(experience: current_xp + quest.xp_reward)
            Rails.logger.info "🌟 [ZEALY WEBHOOK] XP ajoutée: +#{quest.xp_reward}"
          end
        when 'failed'
          completion.progress = 0
          completion.completable = false
          completion.save
        end
      end

      def handle_sprint_started(data)
        Rails.logger.info "🏃 [ZEALY WEBHOOK] Traitement SPRINT_STARTED"
        # TODO: Implémenter la logique pour le début d'un sprint
      end

      def handle_sprint_ended(data)
        Rails.logger.info "🏁 [ZEALY WEBHOOK] Traitement SPRINT_ENDED"
        # TODO: Implémenter la logique pour la fin d'un sprint
      end

      def handle_user_banned(data)
        Rails.logger.info "🚫 [ZEALY WEBHOOK] Traitement USER_BANNED"
        user = User.find_by(zealy_user_id: data[:user][:id])
        return unless user

        # Marquer l'utilisateur comme banni
        user.update!(zealy_user_id: nil)
      end
    end
  end
end
