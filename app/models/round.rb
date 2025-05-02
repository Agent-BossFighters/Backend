class Round < ApplicationRecord
  # Relations
  belongs_to :match, class_name: "TournamentMatch"
  belongs_to :boss_a, class_name: "User", optional: true
  belongs_to :boss_b, class_name: "User", optional: true
  has_one :tournament, through: :match

  # Validations
  validates :round_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :round_number, uniqueness: { scope: :match_id }
  validate :valid_bosses_for_match_type
  validate :valid_points_range

  # Callbacks
  after_save :update_match_points, if: :points_changed?

  private

  def valid_bosses_for_match_type
    return unless match

    if match.arena?
      if boss_a.nil? || boss_b.nil?
        errors.add(:base, "both bosses are required for arena matches")
      end
    else
      if boss_a.present? || boss_b.present?
        errors.add(:base, "bosses should not be set for survival matches")
      end
    end
  end

  def valid_points_range
    return unless match

    if match.arena?
      if team_a_points.negative? || team_a_points > 2 ||
         team_b_points.negative? || team_b_points > 2
        errors.add(:base, "points must be between 0 and 2")
      end
    end
  end

  def points_changed?
    saved_change_to_team_a_points? || saved_change_to_team_b_points?
  end

  def update_match_points
    match.update!(
      team_a_points: match.rounds.sum(:team_a_points),
      team_b_points: match.rounds.sum(:team_b_points)
    )
  end
end
