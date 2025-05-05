class Quest < ApplicationRecord
  # Relations
  has_many :user_quest_completions, foreign_key: :quest_id, primary_key: :quest_id
  has_many :users, through: :user_quest_completions

  # Validations
  validates :quest_id, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :xp_reward, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :progress_required, presence: true, numericality: { greater_than: 0 }
  validates :quest_type, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_type, ->(quest_type) { where(quest_type: quest_type) }
  scope :daily, -> { where(quest_type: "daily") }

  # Méthodes d'instance
  def completable_by?(user, date = Date.current)
    return false unless active?

    # Vérification spécifique pour la quête daily_matches
    if quest_id == "daily_matches"
      # Vérifier si l'utilisateur a joué suffisamment de matchs aujourd'hui
      return false unless has_enough_matches?(user)
    end

    case quest_type
    when "daily"
      !completed_today_by?(user, date)
    when "unique"
      !ever_completed_by?(user)
    when "weekly"
      !completed_this_week_by?(user, date)
    else
      false
    end
  end

  def has_enough_matches?(user, date = Date.current)
    return true unless quest_id == "daily_matches"

    match_count = daily_matches_count(user, date)
    match_count >= progress_required
  end

  def daily_matches_count(user, date = Date.current)
    return 0 unless quest_id == "daily_matches"

    day_start = date.beginning_of_day
    day_end = date.end_of_day

    user.matches.where(created_at: day_start..day_end).count
  end

  def completed_today_by?(user, date = Date.current)
    user_quest_completions
      .where(user: user, completion_date: date)
      .exists?
  end

  def completed_this_week_by?(user, date = Date.current)
    user_quest_completions
      .where(user: user, completion_date: date.beginning_of_week..date.end_of_week)
      .exists?
  end

  def ever_completed_by?(user)
    user_quest_completions
      .where(user: user)
      .exists?
  end

  def progress_for_user(user, date = Date.current)
    user_quest_completions
      .where(user: user, completion_date: date)
      .pick(:progress) || 0
  end

  # Méthodes de classe
  def self.available_quests
    active
  end
end
