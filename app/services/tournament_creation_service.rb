class TournamentCreationService
  attr_reader :errors

  def initialize(user:, tournament_params:)
    @user = user
    @tournament_params = tournament_params
    @errors = []
  end

  def call
    return false unless valid_params?

    ActiveRecord::Base.transaction do
      tournament = create_tournament
      create_empty_teams(tournament) if tournament.auto_create_teams
      tournament
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  rescue => e
    @errors << "Erreur inattendue: #{e.message}"
    false
  end

  private

  def valid_params?
    return add_error("Invalid tournament type") unless valid_tournament_type?
    return add_error("Invalid status") unless valid_status?
    return add_error("Invalid team size") unless valid_team_size?
    true
  end

  def create_tournament
    tournament = Tournament.new(@tournament_params)
    tournament.creator = @user
    
    # Assigner automatiquement le créateur comme boss pour les tournois de survie
    if (tournament.tournament_type == 0 || tournament.tournament_type == 1) && !@tournament_params[:boss_id]
      tournament.boss = @user
    end
    
    tournament.save!
    tournament
  end

  def create_empty_teams(tournament)
    max_teams = tournament.max_teams
    ('A'..'Z').first(max_teams).each_with_index do |letter, index|
      begin
        # Créer l'équipe sans validation
        team = Team.new(
          name: "Team #{letter}",
          tournament_id: tournament.id,
          is_empty: true,
          captain_id: nil
        )
        
        # Sauvegarder sans validation
        team.save(validate: false)
        
      rescue => e
        @errors << "Exception lors de la création de la Team #{letter}: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end
  end

  def valid_tournament_type?
    type = @tournament_params[:tournament_type]
    return false unless type.present?
    type.to_i.between?(0, 2)
  end

  def valid_status?
    status = @tournament_params[:status]
    return false unless status.present?
    status.to_i.between?(0, 4)
  end

  def valid_team_size?
    players = @tournament_params[:players_per_team].to_i
    min_players = @tournament_params[:min_players_per_team].to_i
    players > 0 && min_players > 0 && min_players <= players
  end

  def add_error(message)
    @errors << message
    false
  end
end 