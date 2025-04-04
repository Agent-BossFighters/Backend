module Api
  module V1
    class TeamsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tournament
      before_action :set_team, except: [:index, :create]
      before_action :ensure_captain, only: [:update, :destroy]

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
          captain: current_user, 
          params: team_params
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
          render json: { team: @team.as_json }
        else
          render json: { errors: @team.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @team.destroy
        head :no_content
      end

      def join
        if valid_invitation_code?
          slot_number = next_available_slot
          
          if slot_number.nil?
            render json: { error: "Team is full" }, status: :bad_request
            return
          end
          
          team_member = @team.team_members.new(
            user_id: current_user.id,
            slot_number: slot_number
          )
          
          if team_member.save
            render json: { team_member: team_member.as_json(include: :player) }, status: :created
          else
            render json: { errors: team_member.errors }, status: :unprocessable_entity
          end
        else
          render json: { error: "Invalid invitation code" }, status: :bad_request
        end
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

      private

      def set_tournament
        @tournament = Tournament.find(params[:tournament_id])
      end

      def set_team
        @team = @tournament.teams.find(params[:id])
      end

      def team_params
        params.require(:team).permit(:name, :generate_code, :entry_code)
      end

      def ensure_captain
        unless @team.captain_id == current_user.id
          render json: { error: "Only the team captain can modify the team" },
                 status: :forbidden
        end
      end

      def valid_invitation_code?
        params[:invitation_code] == @team.invitation_code
      end

      def next_available_slot
        used_slots = @team.team_members.pluck(:slot_number)
        (1..@tournament.players_per_team).detect { |slot| !used_slots.include?(slot) }
      end
    end
  end
end 