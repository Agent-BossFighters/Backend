module Api
  module V1
    class QuestsController < Api::V1::BaseController
      before_action :authenticate_user!
      before_action :set_quest, only: [ :show, :update_progress ]

      def index
        begin
          @quests = Quest.active

          render json: {
            quests: @quests.map { |quest|
              # Pour la quête Zealy, vérifier si l'utilisateur est connecté
              if quest.zealy_quest?
                current_progress = current_user.zealy_user_id.present? ? 1 : 0
              else
                # Pour la quête daily_matches, obtenir le nombre réel de matchs
                current_progress = quest.quest_id == "daily_matches" ?
                  quest.daily_matches_count(current_user) :
                  current_user.quest_progress(quest.quest_id)
              end

              {
                id: quest.quest_id,
                title: quest.title,
                description: quest.description,
                quest_type: quest.quest_type,
                xp_reward: quest.xp_reward,
                progress_required: quest.progress_required,
                current_progress: current_progress,
                completed: quest.completed_today_by?(current_user),
                completable: quest.completable_by?(current_user)
              }
            }
          }
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def show
        render json: {
          quest: format_quest(@quest, current_user),
          user_progress: current_user.quest_progress(@quest.quest_id)
        }
      end

      def update_progress
        Rails.logger.info "Updating quest progress for quest: #{@quest.quest_id}, user: #{current_user.id}"
        Rails.logger.info "Received params: #{params.inspect}"

        # Vérifier si l'utilisateur a déjà complété la quête aujourd'hui
        if @quest.completed_today_by?(current_user) && !params[:force]
          Rails.logger.info "Quest already completed today by user"
          return render json: { error: "Cette quête a déjà été complétée aujourd'hui" }, status: :unprocessable_entity
        end

        # Pour la quête Zealy, faire une vérification complète
        if @quest.zealy_quest?
          unless current_user.zealy_user_id.present?
            Rails.logger.error "User not connected to Zealy"
            return render json: { error: "Vous devez être connecté à Zealy pour compléter cette quête" }, status: :unprocessable_entity
          end

          # Vérifier avec l'API Zealy si l'utilisateur a réellement rejoint la communauté
          begin
            zealy_service = ZealyService.new
            community_status = zealy_service.check_community_status(current_user.zealy_user_id)

            unless community_status[:joined]
              Rails.logger.error "User has not joined Zealy community"
              return render json: { error: "Vous devez rejoindre la communauté Zealy pour compléter cette quête" }, status: :unprocessable_entity
            end
          rescue => e
            Rails.logger.error "Failed to verify Zealy community status: #{e.message}"
            return render json: { error: "Impossible de vérifier votre statut Zealy" }, status: :internal_server_error
          end
        end

        @completion = current_user.user_quest_completions.find_or_initialize_by(
          quest_id: @quest.quest_id,
          completion_date: Date.current
        )

        # Assurer qu'on a une valeur de progression
        if params[:progress].nil?
          Rails.logger.error "Progress parameter is missing"
          return render json: { error: "La progression doit être spécifiée" }, status: :unprocessable_entity
        end

        new_progress = params[:progress].to_i
        Rails.logger.info "New progress value: #{new_progress}"

        # Vérifier si la quête est complétable
        unless @quest.completable_by?(current_user)
          Rails.logger.error "Quest not completable by user"
          return render json: { error: "Cette quête n'est pas disponible actuellement" }, status: :unprocessable_entity
        end

        old_progress = @completion.progress || 0
        old_experience = current_user.experience.to_f || 0

        # Si la quête est déjà complétée, ne rien faire sauf si on force la complétion
        if @completion.persisted? && @completion.completed? && !params[:force]
          Rails.logger.info "Quest already completed"
          render json: {
            quest: format_quest(@quest, current_user),
            progress: @completion.progress,
            completed: true,
            experience_gained: 0,
            user_level: current_user.level,
            user_experience: current_user.experience,
            next_level_experience: current_user.level * 1000
          }
          return
        end

        @completion.progress = new_progress

        # Calculer si cette mise à jour va compléter la quête
        will_complete = new_progress >= @quest.progress_required && old_progress.to_i < @quest.progress_required

        if @completion.save
          Rails.logger.info "Quest progress updated successfully"
          # Récupérer les données à jour après sauvegarde
          current_user.reload

          current_level = current_user.level || 1
          current_experience = current_user.experience || 0

          experience_gained = 0
          if will_complete
            experience_gained = @quest.xp_reward
            Rails.logger.info "Quest completed, adding #{experience_gained} XP"

            if current_user.experience.to_f < old_experience.to_f + experience_gained
              current_user.update_columns(experience: old_experience.to_f + experience_gained)
              current_user.reload
              current_experience = current_user.experience || 0
            end
          end

          render json: {
            quest: format_quest(@quest, current_user),
            progress: @completion.progress,
            completed: @completion.completed?,
            experience_gained: experience_gained,
            user_level: current_level,
            user_experience: current_experience,
            next_level_experience: current_level * 1000
          }
        else
          Rails.logger.error "Failed to update quest progress: #{@completion.errors.full_messages}"
          render json: { errors: @completion.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_quest
        @quest = Quest.find_by!(quest_id: params[:id])
      end

      def format_quest(quest, user)
        # Pour la quête Zealy, vérifier si l'utilisateur est connecté
        if quest.zealy_quest?
          current_progress = user.zealy_user_id.present? ? 1 : 0
        else
          current_progress = user.quest_progress(quest.quest_id)
        end

        # Pour la quête daily_matches, utiliser le nombre réel de matchs joués
        if quest.quest_id == "daily_matches"
          custom_progress = quest.daily_matches_count(user)
          current_progress = custom_progress
        end

        is_completed = user.has_completed_quest?(quest.quest_id)
        is_completable = quest.completable_by?(user) && !is_completed

        {
          id: quest.quest_id,
          name: quest.title,
          description: quest.description,
          icon: quest.icon_url,
          quest_type: quest.quest_type,
          current_progress: current_progress,
          progress_required: quest.progress_required,
          completed: is_completed,
          completable: is_completable,
          reward_xp: quest.xp_reward
        }
      end
    end
  end
end
