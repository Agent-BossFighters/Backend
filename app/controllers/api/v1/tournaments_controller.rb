module Api
  module V1
    class TournamentsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tournament, except: [:index, :create]
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
        service = TournamentCreationService.new(creator: current_user, params: tournament_params)
        
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

      private

      def set_tournament
        @tournament = Tournament.find(params[:id])
      end

      def tournament_params
        params = self.params.require(:tournament).permit(
          :name, :tournament_type, :rules, :entry_code,
          :agent_level_required, :players_per_team, :min_players_per_team,
          :max_teams, :is_premium_only, :boss_id, :status, :rounds
        )
        
        # Transformer 'pending' en 'draft'
        params[:status] = 'draft' if params[:status] == 'pending'
        
        # Si le nombre de rounds n'est pas spécifié, utiliser une valeur par défaut
        # basée sur le type de tournoi
        unless params[:rounds].present?
          params[:rounds] = case params[:tournament_type].to_i
                            when 0, 1  # showtime_survival ou showtime_score
                              1
                            when 2      # arena
                              3
                            else
                              1
                            end
        end
        
        # Valider que les rounds sont soit 1 soit 3
        if params[:rounds].to_i != 1 && params[:rounds].to_i != 3
          params[:rounds] = params[:rounds].to_i < 2 ? 1 : 3
        end
        
        params
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