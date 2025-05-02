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
    when "social", "event"
      true # La logique spécifique peut être ajoutée selon les besoins
    else
      false
    end
  end

  def has_enough_matches?(user, date = Date.current)
    # Pour la quête daily_matches, vérifier si l'utilisateur a joué 5 matchs aujourd'hui
    if quest_id == "daily_matches"
      # Utiliser la même méthode que daily_matches_count pour la cohérence
      match_count = daily_matches_count(user, date)
      return match_count >= progress_required
    end

    # Pour les autres quêtes, toujours retourner true (pas de vérification supplémentaire)
    true
  end

  def daily_matches_count(user, date = Date.current)
    # Pour la quête daily_matches, retourner le nombre de matchs joués aujourd'hui
    if quest_id == "daily_matches"
      # Définir la plage de la journée complète
      day_start = date.beginning_of_day
      day_end = date.end_of_day

      # Compter les matchs créés aujourd'hui
      matches_count = user.matches.where("created_at BETWEEN ? AND ?", day_start, day_end).count

      return matches_count
    end

    # Pour les autres quêtes, retourner 0
    0
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
    # Par défaut, retourner toutes les quêtes actives
    active
  end
end
