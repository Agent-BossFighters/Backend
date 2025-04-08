module Api
  module V1
    class QuestsController < Api::V1::BaseController
      before_action :authenticate_user!
      before_action :set_quest, only: [:show, :update_progress]

      def index
        begin
          @quests = Quest.active

          render json: {
            quests: @quests.map { |quest|
              # Pour la quête daily_matches, obtenir le nombre réel de matchs
              current_progress = quest.quest_id == 'daily_matches' ?
                quest.daily_matches_count(current_user) :
                current_user.quest_progress(quest.quest_id)


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
        @completion = current_user.user_quest_completions.find_or_initialize_by(
          quest_id: @quest.quest_id,
          completion_date: Date.current
        )

        new_progress = params[:progress].to_i

        # Assurer qu'on a une valeur de progression
        if params[:progress].nil?
          return render json: { error: "La progression doit être spécifiée" }, status: :unprocessable_entity
        end

        unless @quest.completable_by?(current_user)
          return render json: { error: "Cette quête n'est pas disponible actuellement" }, status: :unprocessable_entity
        end


        old_progress = @completion.progress || 0  # Utiliser 0 si nil
        old_experience = current_user.experience.to_f || 0  # Sauvegarder la valeur d'expérience avant mise à jour

        # Si la quête est déjà complétée, ne rien faire sauf si on force la complétion
        if @completion.persisted? && @completion.completed? && !params[:force]
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
          # Récupérer les données à jour après sauvegarde
          # Force un rechargement des données utilisateur
          current_user.reload

          # S'assurer que les valeurs ne sont jamais nil
          current_level = current_user.level || 1
          current_experience = current_user.experience || 0


          # Si la quête est complétée maintenant mais ne l'était pas avant, assurons-nous que l'XP est attribuée
          experience_gained = 0
          if will_complete
            experience_gained = @quest.xp_reward

            # S'assurer que les valeurs dans la réponse sont cohérentes
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
            next_level_experience: current_level * 1000 # Même formule que dans check_level_up
          }
        else
          render json: { errors: @completion.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_quest
        @quest = Quest.find_by!(quest_id: params[:id])
      end

      def format_quest(quest, user)
        current_progress = user.quest_progress(quest.quest_id)

        # Pour la quête daily_matches, utiliser le nombre réel de matchs joués
        if quest.quest_id == 'daily_matches'
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
