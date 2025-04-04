class TournamentMatch < ApplicationRecord
  enum :match_type, {
    arena: 0,
    survival: 1
  }

  enum :status, {
    scheduled: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  # Relations
  belongs_to :tournament
  belongs_to :team_a, class_name: 'Team'
  belongs_to :team_b, class_name: 'Team', optional: true
  belongs_to :winner, class_name: 'Team', optional: true
  belongs_to :boss, class_name: 'User', optional: true
  has_many :rounds, dependent: :destroy

  # Validations
  validates :match_type, presence: true
  validates :status, presence: true
  validates :round_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :scheduled_time, presence: true
  validate :teams_belong_to_tournament
  validate :validate_match_type_consistency
  validate :validate_team_b_presence

  # Scopes
  scope :upcoming, -> { where(status: :scheduled).where('scheduled_time > ?', Time.current) }
  scope :in_progress, -> { where(status: :in_progress) }
  scope :completed, -> { where(status: :completed) }

  def completed?
    status == 'completed'
  end

  private

  def teams_belong_to_tournament
    unless team_a.tournament_id == tournament_id
      errors.add(:team_a, "must belong to the same tournament")
    end

    # Pour les tournois d'arène, on vérifie aussi team_b
    # Pour les tournois de survie, team_b est optionnel
    if team_b.present?
      unless team_b.tournament_id == tournament_id
        errors.add(:team_b, "must belong to the same tournament")
      end
    end
  end

  def validate_match_type_consistency
    unless tournament.present?
      return
    end

    # For arena tournaments, match type must be arena
    if tournament.arena? && !arena?
      errors.add(:match_type, "must be arena for arena tournaments")
    end

    # For survival tournaments, match type must be survival
    if (tournament.showtime_survival? || tournament.showtime_score?) && !survival?
      errors.add(:match_type, "must be survival for survival tournaments")
    end
  end

  def validate_team_b_presence
    if arena? && !team_b.present?
      errors.add(:team_b, "must be present for arena tournaments")
    end
  end
end 