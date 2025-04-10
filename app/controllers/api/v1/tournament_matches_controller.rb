module Api
  module V1
    class TournamentMatchesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!
      before_action :set_tournament
      before_action :set_match, except: [:index, :create]
      before_action :ensure_admin, only: [:create, :update_results]

      def index
        @matches = @tournament.tournament_matches
                            .includes(:team_a, :team_b, :boss, :rounds)
                            .order(round_number: :asc, scheduled_time: :asc)
        
        render json: {
          matches: @matches.as_json(
            include: {
              team_a: { only: [:id, :name] },
              team_b: { only: [:id, :name] },
              boss: { only: [:id, :username] },
              winner: { only: [:id, :name] }
            }
          )
        }
      end

      def show
        render json: {
          match: @match.as_json(
            include: {
              team_a: { only: [:id, :name] },
              team_b: { only: [:id, :name] },
              boss: { only: [:id, :username] },
              winner: { only: [:id, :name] },
              rounds: {
                include: {
                  boss_a: { only: [:id, :username] },
                  boss_b: { only: [:id, :username] }
                }
              }
            },
            methods: [:completed?]
          )
        }
      end

      def create
        service = MatchManagementService.new(
          tournament: @tournament, 
          params: match_params.merge(current_user_id: current_user.id)
        )
        
        if match = service.create_match
          render json: { match: match.as_json(include: [:team_a, :team_b]) }, status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def update
        update_results
      end

      def update_results
        # Extraire les paramètres de résultats
        results = results_params
        
        # Journaliser les paramètres
        Rails.logger.info("Mise à jour des résultats pour le match #{@match.id}")
        Rails.logger.info("Paramètres de résultats : #{results.inspect}")
        
        # S'assurer que le service a accès au match
        service = MatchManagementService.new(
          tournament: @tournament, 
          params: { current_user_id: current_user.id }
        )
        
        if service.update_results(match: @match, results: results)
          # Recharger le match depuis la base de données pour s'assurer d'avoir les données à jour
          @match.reload
          
          Rails.logger.info("Match mis à jour avec succès. Nouveaux attributs : #{@match.attributes.inspect}")
          
          render json: { 
            match: @match.as_json(
              include: {
                team_a: { only: [:id, :name] },
                team_b: { only: [:id, :name] },
                winner: { only: [:id, :name] },
                rounds: { only: [:round_number, :team_a_damage, :team_b_damage, :team_a_points, :team_b_points] }
              }
            )
          }
        else
          Rails.logger.error("Erreur lors de la mise à jour des résultats : #{service.errors.inspect}")
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_tournament
        @tournament = Tournament.find(params[:tournament_id])
      end

      def set_match
        @match = @tournament.tournament_matches.find(params[:id])
      end

      def match_params
        params.require(:match).permit(
          :round_number, :scheduled_time, :team_a_id, :team_b_id, :boss_id, :status
        )
      end

      def results_params
        # Journaliser tous les paramètres pour le débogage
        Rails.logger.info("Paramètres reçus : #{params.inspect}")
        
        if @tournament.arena?
          params.require(:results).permit(
            rounds: [:round_number, :team_a_damage, :team_b_damage]
          )
        else
          # Pour les tournois de survie, accepter différents formats possibles
          survival_params = nil
          
          if params[:results].present?
            survival_params = params.require(:results).permit(:survival_time)
          elsif params[:match] && params[:match][:survival_time].present?
            survival_params = { survival_time: params[:match][:survival_time] }
          elsif params[:match] && params[:match][:team_a_points].present?
            survival_params = { survival_time: params[:match][:team_a_points] }
          elsif params[:survival_time].present?
            survival_params = { survival_time: params[:survival_time] }
          elsif params[:team_a_points].present?
            survival_params = { survival_time: params[:team_a_points] }
          else
            survival_params = { survival_time: params[:score] || 0 }
          end
          
          Rails.logger.info("Paramètres de survie extraits : #{survival_params.inspect}")
          survival_params
        end
      end

      def ensure_admin
        unless @tournament.tournament_admins.exists?(user: current_user)
          render json: { error: 'Only tournament admins can manage matches' },
                 status: :forbidden
        end
      end
    end
  end
end 