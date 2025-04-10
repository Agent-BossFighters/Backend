class Tournament < ApplicationRecord
  # Enums
  enum :tournament_type, {
    showtime_survival: 0,
    showtime_score: 1,
    arena: 2
  }

  enum :status, {
    draft: 0,
    open: 1,
    in_progress: 2,
    completed: 3,
    cancelled: 4
  }

  # Relations
  belongs_to :creator, class_name: 'User'
  belongs_to :boss, class_name: 'User', optional: true
  has_many :tournament_admins, dependent: :destroy
  has_many :admins, through: :tournament_admins, source: :user
  has_many :teams, dependent: :destroy
  has_many :tournament_matches, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :tournament_type, presence: true
  validates :status, presence: true
  validates :players_per_team, presence: true, 
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }
  validates :max_teams, presence: true,
            numericality: { only_integer: true, greater_than: 1 }
  validates :agent_level_required, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :entry_code, uniqueness: true, allow_nil: true
  validates :min_players_per_team, numericality: { only_integer: true, greater_than: 2 },
            if: :arena?
  validates :rounds, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validate :creator_must_be_premium
  validate :boss_required_for_survival
  validate :valid_team_size_for_type

  # Callbacks
  after_create :add_creator_as_admin
  before_validation :set_default_rounds

  # Helper methods
  def registration_open?
    open?
  end

  def full?
    teams.count >= max_teams
  end

  def survival?
    showtime_survival? || showtime_score?
  end

  # Détermine le nombre de rounds par défaut en fonction du type de tournoi
  def default_rounds
    if arena?
      3  # Par défaut, 3 rounds pour les tournois d'arène
    else
      1  # Pour les tournois de survie, un seul round par défaut
    end
  end

  private

  # Définit le nombre de rounds par défaut avant validation
  def set_default_rounds
    self.rounds ||= default_rounds
  end

  def creator_must_be_premium
    unless creator&.premium?
      errors.add(:creator, "must be a premium user to create tournaments")
    end
  end

  def boss_required_for_survival
    if (showtime_survival? || showtime_score?) && boss.nil?
      errors.add(:boss, "is required for survival tournaments")
    end
  end

  def valid_team_size_for_type
    if arena?
      if players_per_team != 5
        errors.add(:players_per_team, "must be 5 for arena tournaments")
      end
    else
      if players_per_team > 4
        errors.add(:players_per_team, "must be between 1 and 4 for survival tournaments")
      end
    end
  end

  def add_creator_as_admin
    tournament_admins.create!(user: creator, is_creator: true)
  end
end
