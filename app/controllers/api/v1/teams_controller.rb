module Api
  module V1
    class TeamsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tournament
      before_action :set_team, except: [:index, :create, :join]
      before_action :ensure_captain, only: [:update, :destroy, :kick]

      def index
        @teams = @tournament.teams.includes(:captain, :team_members => :player)
        render json: {
          teams: @teams.as_json(
            include: {
              captain: { only: [:id, :username] },
              team_members: {
                include: {
                  player: { only: [:id, :username, :level] }
                }
              }
            },
            methods: [:members_count]
          )
        }
      end

      def show
        render json: {
          team: @team.as_json(
            include: {
              captain: { only: [:id, :username] },
              team_members: {
                include: {
                  player: { only: [:id, :username, :level] }
                }
              }
            },
            methods: [:members_count]
          )
        }
      end

      def create
        service = TeamRegistrationService.new(
          tournament: @tournament, 
          user: current_user,
          team_params: team_params
        )
        
        if @team = service.call
          render json: {
            team: @team.as_json(
              include: {
                captain: { only: [:id, :username] },
                team_members: {
                  include: {
                    player: { only: [:id, :username, :level] }
                  }
                }
              },
              methods: [:members_count]
            )
          }, status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @team.update(team_params)
          render json: {
            team: @team.as_json(
              include: {
                captain: { only: [:id, :username] },
                team_members: {
                  include: {
                    player: { only: [:id, :username, :level] }
                  }
                }
              },
              methods: [:members_count]
            )
          }
        else
          render json: { errors: @team.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @team.destroy
        head :no_content
      end

      def join
        service_params = { slot_number: params[:slot_number] }
        
        # Ajouter les paramètres conditionnellement
        service_params[:id] = params[:id] if params[:id].present?
        service_params[:invitation_code] = params[:invitation_code] if params[:invitation_code].present?
        service_params[:team_letter] = params[:team_letter] if params[:team_letter].present?
        service_params[:entry_code] = params[:entry_code] if params[:entry_code].present?
        
        # Si le paramètre private est présent, l'ajouter à service_params
        service_params[:private] = params[:private] if params[:private].present?
        
        # Valider que nous avons au moins un identifiant d'équipe ou un code d'invitation
        if service_params[:id].blank? && service_params[:invitation_code].blank? && service_params[:team_letter].blank?
          return render json: { error: "Team ID, invitation code, or team letter is required" }, status: :unprocessable_entity
        end
        
        # Si nous avons un ID d'équipe, vérifier si l'équipe existe et si elle requiert un code d'invitation
        if service_params[:id].present?
          team = Team.find_by(id: service_params[:id])
          
          if team.present? && team.invitation_code.present? && service_params[:invitation_code] != team.invitation_code
            return render json: { error: "Invalid invitation code for private team" }, status: :unauthorized
          end
        end
        
        service = TeamRegistrationService.new(
          tournament: @tournament,
          user: current_user,
          team_params: service_params
        )
        
        if service.call
          # S'assurer que is_empty est toujours à false après une jointure réussie
          if service.team.is_empty && service.team.team_members.count > 0
            service.team.update_column(:is_empty, false)
          end
          
          render json: service.team, include: [
            :players, 
            :captain, 
            { team_members: { include: :player } }
          ], status: :ok
        else
          Rails.logger.error("Join team failed: #{service.errors.inspect}")
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def broadcast_team_update(team = nil)
        team ||= @team
        # Ajouter ici la logique de broadcast si nécessaire
      end

      def leave
        team_member = @team.team_members.find_by(player: current_user)
        
        if team_member.nil?
          render json: { error: "You are not a member of this team" }, status: :bad_request
          return
        end
        
        if team_member.player_id == @team.captain_id
          render json: { error: "Team captain cannot leave" }, status: :bad_request
          return
        end
        
        team_member.destroy
        head :no_content
      end

      def kick
        team_member = @team.team_members.find_by(user_id: params[:member_id])
        
        if team_member.nil?
          render json: { error: "Member not found" }, status: :not_found
          return
        end
        
        if team_member.user_id == @team.captain_id
          render json: { error: "Cannot kick the team captain" }, status: :bad_request
          return
        end
        
        if team_member.destroy
          head :no_content
        else
          render json: { errors: team_member.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_tournament
        @tournament = Tournament.find(params[:tournament_id])
      end

      def set_team
        @team = @tournament.teams.find(params[:id])
      end

      def team_params
        params.require(:team).permit(
          :name, :private, :invitation_code, :letter
        )
      end

      def ensure_captain
        unless @team.captain_id == current_user.id
          render json: { error: "Only the team captain can modify the team" },
                 status: :forbidden
        end
      end

      def team_joinable?
        # Si l'équipe n'a pas de code d'invitation, elle est publique
        return true if @team.invitation_code.nil?
        # Sinon, vérifier le code d'invitation
        params[:invitation_code] == @team.invitation_code
      end

      def next_available_slot
        used_slots = @team.team_members.pluck(:slot_number)
        (1..@tournament.players_per_team).detect { |slot| !used_slots.include?(slot) }
      end
    end
  end
end 