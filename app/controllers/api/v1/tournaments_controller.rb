module Api
  module V1
    class TournamentsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tournament, except: [:index, :create, :my_tournaments]
      before_action :ensure_premium_user, only: [:create]
      before_action :ensure_admin, only: [:update, :destroy]

      def index
        @tournaments = Tournament.includes(:creator, :boss, :teams)
                               .order(created_at: :desc)
                               .limit(20)
        
        render json: {
          tournaments: @tournaments.as_json(
            include: { 
              creator: { only: [:id, :username] },
              boss: { only: [:id, :username] },
              teams: { only: [:id, :name] }
            }
          )
        }
      end

      def show
        render json: {
          tournament: @tournament.as_json(
            include: {
              creator: { only: [:id, :username] },
              boss: { only: [:id, :username] },
              teams: {
                include: {
                  captain: { only: [:id, :username] }
                }
              }
            }
          )
        }
      end

      def create
        # Permettre des paramètres à la racine ou dans l'objet tournament
        tournament_data = params[:tournament].present? ? params[:tournament] : params
        
        # Convertir explicitement les types pour éviter les erreurs de validation
        processed_params = {
          name: tournament_data[:name],
          tournament_type: tournament_data[:tournament_type].to_i,
          status: tournament_data[:status].to_i,
          rules: tournament_data[:rules],
          agent_level_required: tournament_data[:agent_level_required].to_i,
          players_per_team: tournament_data[:players_per_team].to_i,
          min_players_per_team: tournament_data[:min_players_per_team].to_i,
          max_teams: tournament_data[:max_teams].to_i,
          rounds: tournament_data[:rounds].to_i,
          auto_create_teams: tournament_data[:auto_create_teams] == true || tournament_data[:auto_create_teams] == "true"
        }
        
        # Détection du type de tournoi pour configurer correctement le boss
        if processed_params[:tournament_type] <= 1 && !tournament_data[:boss_id]
          processed_params[:boss_id] = current_user.id
        end
        
        service = TournamentCreationService.new(
          user: current_user, 
          tournament_params: processed_params
        )
        
        if @tournament = service.call
          render json: { tournament: @tournament.as_json(include: :creator) }, status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @tournament.update(tournament_params)
          render json: { tournament: @tournament.as_json }
        else
          render json: { errors: @tournament.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @tournament.destroy
        head :no_content
      end

      def my_tournaments
        # Récupérer les IDs des équipes dans lesquelles l'utilisateur est membre
        member_team_ids = TeamMember.where(user_id: current_user.id).pluck(:team_id)
        
        # Récupérer les IDs des équipes dont l'utilisateur est capitaine
        captain_team_ids = Team.where(captain_id: current_user.id).pluck(:id)
        
        # Combiner tous les IDs d'équipes
        all_team_ids = (member_team_ids + captain_team_ids).uniq
        
        # Récupérer tous les tournois associés à ces équipes
        @tournaments = Tournament.joins(:teams)
                                 .where(teams: { id: all_team_ids })
                                 .includes(:creator, :boss, :teams)
                                 .order(created_at: :desc)
                                 .distinct
        
        render json: {
          tournaments: @tournaments.as_json(
            include: { 
              creator: { only: [:id, :username] },
              boss: { only: [:id, :username] },
              teams: { only: [:id, :name] }
            }
          )
        }
      end

      private

      def set_tournament
        @tournament = Tournament.find(params[:id])
      end

      def tournament_params
        params.require(:tournament).permit(
          :name, :tournament_type, :status, :rules, 
          :agent_level_required, :players_per_team, 
          :min_players_per_team, :max_teams, 
          :rounds, :is_premium_only, :boss_id, :auto_create_teams
        )
      end

      def ensure_premium_user
        unless current_user.premium?
          render json: { error: 'Only premium users can create tournaments' }, status: :forbidden
        end
      end

      def ensure_admin
        unless @tournament.tournament_admins.exists?(user: current_user)
          render json: { error: 'Not authorized' },
                 status: :forbidden
        end
      end
    end
  end
end 