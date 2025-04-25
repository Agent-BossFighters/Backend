module Api
  module V1
    class ZealyController < Api::V1::BaseController
      before_action :authenticate_user!, except: [:webhook]

      def connect
        # Générer l'URL de redirection Zealy
        redirect_url = "https://zealy.io/c/agentbossfighterstest/join"

        render json: {
          redirect_url: redirect_url
        }
      end

      def callback
        # Récupérer l'ID utilisateur Zealy depuis les paramètres
        zealy_user_id = params[:user_id]

        if zealy_user_id.present?
          # Mettre à jour l'utilisateur avec son ID Zealy
          current_user.update!(zealy_user_id: zealy_user_id)

          # Synchroniser les quêtes Zealy
          Quest.sync_with_zealy(current_user)

          render json: {
            message: "Connexion Zealy réussie",
            user: current_user
          }
        else
          render json: { error: "ID utilisateur Zealy manquant" }, status: :unprocessable_entity
        end
      end

      def sync_quests
        # Synchroniser les quêtes Zealy pour l'utilisateur
        Quest.sync_with_zealy(current_user)

        render json: {
          message: "Quêtes Zealy synchronisées avec succès"
        }
      end

      def community
        # Récupérer les informations de la communauté Zealy
        community_info = ZealyService.new.get_community_info(params[:community])

        render json: community_info
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def webhook
        # Vérifier que c'est bien une requête POST
        unless request.post?
          Rails.logger.error("Invalid HTTP method: #{request.method}")
          return render json: { error: 'Method not allowed' }, status: :method_not_allowed
        end

        # Vérifier les en-têtes requis
        unless request.headers['User-Agent'] == 'Zealy-Webhook' &&
               request.headers['Content-Type'].to_s.include?('application/json')
          Rails.logger.error("Invalid headers: #{request.headers}")
          return render json: { error: 'Invalid headers' }, status: :bad_request
        end

        # Parser le payload
        begin
          payload = JSON.parse(request.raw_post)
        rescue JSON::ParserError => e
          Rails.logger.error("Invalid JSON payload: #{e.message}")
          return render json: { error: 'Invalid JSON payload' }, status: :bad_request
        end

        # Vérifier le secret
        webhook_secret = ENV['ZEALY_WEBHOOK_SECRET']
        unless payload['secret'] == webhook_secret
          Rails.logger.error("Invalid webhook secret received")
          return render json: { error: 'Invalid webhook secret' }, status: :unauthorized
        end

        # Ne traiter que l'événement QUEST_SUCCEEDED
        unless payload['type'] == 'QUEST_SUCCEEDED'
          return render json: { status: 'ignored' }, status: :ok
        end

        # Traiter l'événement
        handle_quest_succeeded(payload['data'])
        render json: { status: 'success' }, status: :ok

      rescue StandardError => e
        Rails.logger.error("Webhook error: #{e.message}")
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def handle_quest_succeeded(data)
        return unless data['user'] && data['quest']

        user = User.find_by(zealy_user_id: data['user']['id'])
        quest = Quest.find_by(zealy_quest_id: data['quest']['id'])

        return unless user && quest

        # Créer ou mettre à jour la complétion de la quête
        UserQuestCompletion.create_or_find_by!(
          user: user,
          quest: quest,
          completion_date: Date.current,
          progress: quest.progress_required
        )

        # Mettre à jour l'XP de l'utilisateur
        current_xp = user.experience || 0
        user.update!(experience: current_xp + quest.xp_reward)
      end
    end
  end
end
