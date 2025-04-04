class Team < ApplicationRecord
  # Relations
  belongs_to :tournament
  belongs_to :captain, class_name: 'User'
  has_many :team_members, dependent: :destroy
  has_many :players, through: :team_members, source: :player
  has_many :tournament_matches_as_team_a, class_name: 'TournamentMatch', foreign_key: 'team_a_id'
  has_many :tournament_matches_as_team_b, class_name: 'TournamentMatch', foreign_key: 'team_b_id'

  # Validations
  validates :name, presence: true, uniqueness: { scope: :tournament_id }
  validates :invitation_code, uniqueness: true, allow_nil: true
  validate :captain_not_in_other_teams
  validate :correct_team_size
  validate :players_not_boss_if_survival

  # Callbacks
  after_create :add_captain_as_member

  def total_points
    tournament_matches_as_team_a.sum(:team_a_points) + tournament_matches_as_team_b.sum(:team_b_points)
  end

  def members_count
    team_members.count
  end

  private

  def captain_not_in_other_teams
    return unless tournament && captain
    
    other_teams = tournament.teams.where.not(id: id)
    if other_teams.joins(:team_members).where(team_members: { user_id: captain_id }).exists?
      errors.add(:captain, "is already in another team in this tournament")
    end
  end

  def correct_team_size
    return unless tournament
    
    if team_members.size > tournament.players_per_team
      errors.add(:base, "team cannot have more than #{tournament.players_per_team} players")
    end
  end

  def players_not_boss_if_survival
    return unless tournament && (tournament.showtime_survival? || tournament.showtime_score?)
    
    if players.include?(tournament.boss)
      errors.add(:base, "team members cannot include the tournament boss in survival mode")
    end
  end

  def add_captain_as_member
    team_members.create!(
      user_id: captain_id,
      slot_number: 1,
      is_boss_eligible: tournament.arena?
    )
  end
end 