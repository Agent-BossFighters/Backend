class TeamMember < ApplicationRecord
  # Relations
  belongs_to :team
  belongs_to :player, class_name: "User", foreign_key: "user_id"
  has_one :tournament, through: :team

  # Validations
  validates :slot_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :slot_number, uniqueness: { scope: :team_id }
  validates :user_id, uniqueness: { scope: :team_id }
  validate :user_not_in_other_teams
  validate :slot_number_within_team_size
  validate :user_meets_level_requirement

  private

  def user_not_in_other_teams
    return unless team&.tournament && player

    other_teams = team.tournament.teams.where.not(id: team_id)
    if other_teams.joins(:team_members).where(team_members: { user_id: user_id }).exists?
      errors.add(:player, "is already in another team in this tournament")
    end
  end

  def slot_number_within_team_size
    return unless team&.tournament

    if slot_number > team.tournament.players_per_team
      errors.add(:slot_number, "cannot be greater than the maximum team size")
    end
  end

  def user_meets_level_requirement
    return unless team&.tournament && player

    if team.tournament.agent_level_required > 0 && player.level < team.tournament.agent_level_required
      errors.add(:player, "does not meet the minimum level requirement")
    end
  end
end
