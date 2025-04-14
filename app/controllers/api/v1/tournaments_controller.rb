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
            },
            methods: [:players_count]
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
        
        # Ajouter le code d'entrée s'il est présent
        if tournament_data[:entry_code].present?
          processed_params[:entry_code] = tournament_data[:entry_code].to_s
        end
        
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
        # Récupérer les paramètres originaux du tournoi
        original_max_teams = @tournament.max_teams
        
        # Traiter les options supplémentaires
        options = params[:options] || {}
        delete_higher_id_teams = options[:delete_higher_id_teams].present? ? 
                                (options[:delete_higher_id_teams].to_s == "true") : false
        create_missing_teams = options[:create_missing_teams].present? ? 
                              (options[:create_missing_teams].to_s == "true") : false

        # Mettre à jour le tournoi
        if @tournament.update(tournament_params)
          # Gérer la suppression des équipes si le nombre max a été réduit
          if tournament_params[:max_teams].present? && 
             tournament_params[:max_teams].to_i < original_max_teams &&
             delete_higher_id_teams
            
            # Calculer combien d'équipes doivent être gardées
            teams_to_keep = tournament_params[:max_teams].to_i
            
            # Récupérer toutes les équipes du tournoi
            all_teams = @tournament.teams
            current_teams_count = all_teams.count
            
            # Si nous avons plus d'équipes que nécessaire
            if current_teams_count > teams_to_keep
              # Trier par ID décroissant (supprimer les équipes avec les ID les plus élevés)
              teams_by_id_desc = all_teams.order(id: :desc).to_a
              # Prendre les équipes excédentaires (avec les ID les plus élevés)
              teams_to_delete = teams_by_id_desc.first(current_teams_count - teams_to_keep)
              
              # Supprimer chaque équipe et ses membres
              teams_to_delete.each do |team|
                begin
                  # Supprimer d'abord tous les membres de l'équipe
                  team.team_members.destroy_all
                  
                  # Puis supprimer l'équipe elle-même
                  team.destroy
                rescue => e
                  next
                end
              end
            end
          end
          
          # Gérer la création de nouvelles équipes si le nombre max a été augmenté
          if tournament_params[:max_teams].present? && 
             tournament_params[:max_teams].to_i > original_max_teams &&
             create_missing_teams
            
            # Calculer combien d'équipes doivent être créées
            current_teams_count = @tournament.teams.count
            new_max_teams = tournament_params[:max_teams].to_i
            teams_to_create = new_max_teams - current_teams_count
            
            if teams_to_create > 0
              
              # Définir le créateur du tournoi comme capitaine temporaire
              # Si le créateur n'est pas disponible, utilisez l'utilisateur actuel
              temp_captain_id = @tournament.creator_id || current_user.id
              
              # Déterminer les lettres disponibles pour les nouvelles équipes
              existing_letters = @tournament.teams.pluck(:name).map { |name| name.split(' ').last }
              
              # Créer les équipes manquantes
              teams_created = []
              
              teams_to_create.times do |i|
                # Trouver la prochaine lettre disponible
                next_letter = nil
                ('A'..'Z').each do |letter|
                  unless existing_letters.include?(letter)
                    next_letter = letter
                    existing_letters << letter
                    break
                  end
                end
                
                # Si toutes les lettres sont utilisées, utiliser un index numérique
                name = next_letter ? "Team #{next_letter}" : "Team #{current_teams_count + i + 1}"
                
                begin
                  # Créer l'équipe sans capitaine
                  team = Team.new(
                    name: name,
                    is_empty: true,
                    captain_id: nil,  # Pas de capitaine par défaut
                    tournament_id: @tournament.id
                  )
                  
                  # Désactiver les validations pour permettre la création sans capitaine
                  team.save(validate: false)
                  
                  teams_created << team
                rescue => e
                end
              end
            end
          end
          
          render json: { tournament: @tournament.reload.as_json }
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
            },
            methods: [:players_count]
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
          :rounds, :is_premium_only, :boss_id, :auto_create_teams, :entry_code
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