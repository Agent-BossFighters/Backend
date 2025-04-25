module Api
  module V1
    class ZealyWebhookController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!

      def webhook
        puts "🔵 Webhook Zealy reçu !"

        payload = request.body.read
        event = JSON.parse(payload, symbolize_names: true)

        # Vérifier le secret
        unless event[:secret] == ENV['ZEALY_WEBHOOK_SECRET']
          puts "❌ Secret invalide"
          return render json: { error: "Invalid secret" }, status: :unauthorized
        end

        puts "🟢 Event Zealy détecté : #{event[:type]}"

        case event[:type]
        when 'QUEST_SUCCEEDED'
          handle_quest_succeeded(event[:data])
        when 'QUEST_CLAIMED'
          handle_quest_claimed(event[:data])
        when 'QUEST_FAILED'
          handle_quest_failed(event[:data])
        when 'QUEST_CLAIM_STATUS_UPDATED'
          handle_quest_claim_status_updated(event[:data])
        else
          puts "⚠️ Webhook ignoré : #{event[:type]}"
        end

        render json: { received: true }
      rescue JSON::ParserError => e
        puts "❌ Erreur JSON : #{e.message}"
        render json: { error: e.message }, status: :bad_request
      end

      private

      def handle_quest_succeeded(data)
        puts "✅ Quête réussie détectée"

        # Récupérer l'utilisateur via son ID Zealy
        user = User.find_by(zealy_user_id: data[:user][:id])

        if user.nil?
          puts "❌ Utilisateur non trouvé avec l'ID Zealy : #{data[:user][:id]}"
          return
        end

        # Récupérer la quête via son ID Zealy
        quest = Quest.find_by(zealy_quest_id: data[:quest][:id])

        if quest.nil?
          puts "❌ Quête non trouvée avec l'ID Zealy : #{data[:quest][:id]}"
          return
        end

        # Créer ou mettre à jour la complétion de la quête
        completion = user.user_quest_completions.find_or_initialize_by(
          quest_id: quest.quest_id,
          completion_date: Date.current
        )

        completion.progress = quest.progress_required
        completion.save!

        puts "🎉 Quête marquée comme complétée pour #{user.email}"
      end

      def handle_quest_claimed(data)
        puts "🎯 Quête réclamée détectée"
        # Logique pour gérer les quêtes réclamées
      end

      def handle_quest_failed(data)
        puts "❌ Quête échouée détectée"
        # Logique pour gérer les quêtes échouées
      end

      def handle_quest_claim_status_updated(data)
        puts "🔄 Statut de réclamation de quête mis à jour"
        # Logique pour gérer les mises à jour de statut
      end
    end
  end
end
