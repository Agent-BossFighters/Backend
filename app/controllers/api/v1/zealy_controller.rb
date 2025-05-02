module Api
  module V1
    class ZealyController < Api::V1::BaseController
      before_action :authenticate_user!, except: [:connect]

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

          # Vérifier et compléter la quête Zealy si nécessaire
          handle_zealy_quest_completion(current_user)

          render json: {
            message: "Connexion Zealy réussie",
            user: current_user
          }
        else
          render json: { error: "ID utilisateur Zealy manquant" }, status: :unprocessable_entity
        end
      end

      def check_community_status
        begin
          Rails.logger.info "Checking community status for user: #{current_user.id}"

          # Vérifier si l'utilisateur a un ID Zealy
          unless current_user.zealy_user_id.present?
            return render json: { joined: false, error: "User not connected to Zealy" }
          end

          # Vérifier le statut de la communauté
          status = ZealyService.new.check_community_status(current_user.zealy_user_id)

          # Ajouter le statut de la communauté spécifique
          community = params[:community]
          if community.present?
            status[:community] = community
            status[:community_joined] = status[:joined] && status[:quest_completed]
          end

          render json: status
        rescue => e
          Rails.logger.error("Error checking community status: #{e.message}")
          render json: { joined: false, error: e.message }, status: :internal_server_error
        end
      end

      def sync_quests
        begin
          Rails.logger.info "Starting Zealy quest sync for user: #{current_user.id}"

          # Vérifier si l'utilisateur a un ID Zealy
          unless current_user.zealy_user_id.present?
            return render json: { error: "User not connected to Zealy" }, status: :unprocessable_entity
          end

          # Synchroniser les quêtes Zealy pour l'utilisateur
          Quest.sync_with_zealy(current_user)

          render json: {
            message: "Quêtes Zealy synchronisées avec succès"
          }
        rescue => e
          Rails.logger.error("Error syncing Zealy quests: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def check_quest_status
        quest = Quest.find_by!(quest_id: params[:quest_id])

        if quest.quest_id == 'zealy_connect'
          # Vérifier si l'utilisateur est connecté à Zealy
          is_completed = current_user.zealy_user_id.present?

          render json: {
            completed: is_completed,
            progress: is_completed ? 1 : 0
          }
        else
          render json: { error: "Quête non supportée" }, status: :unprocessable_entity
        end
      end

      def community
        # Récupérer les informations de la communauté Zealy
        community_info = ZealyService.new.get_community_info(params[:community])

        render json: community_info
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def handle_zealy_quest_completion(user)
        quest = Quest.find_by(quest_id: 'zealy_connect')
        return unless quest

        # Vérifier si la quête n'est pas déjà complétée
        unless quest.completed_today_by?(user)
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
end
