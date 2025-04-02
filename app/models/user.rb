class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Associations
  has_many :nfts, foreign_key: :owner, primary_key: :id, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :user_slots, dependent: :destroy
  has_many :user_builds, dependent: :destroy
  has_many :user_recharges, dependent: :destroy
  has_many :player_cycles, dependent: :destroy
  has_many :slots, through: :user_slots
  has_many :transactions, dependent: :destroy
  has_many :user_quest_completions, dependent: :destroy
  has_many :quests, through: :user_quest_completions

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :experience, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_create :set_default_premium_status
  before_validation :ensure_default_level_exp
  after_create :send_welcome_email

  # Méthodes pour les quêtes
  def available_quests(date = Date.current)
    Quest.active.select { |quest| quest.completable_by?(self, date) }
  end

  def daily_quests(date = Date.current)
    available_quests(date).select { |quest| quest.type == 'daily' }
  end

  def weekly_quests(date = Date.current)
    available_quests(date).select { |quest| quest.type == 'weekly' }
  end

  def completed_quests(date = Date.current)
    user_quest_completions
      .includes(:quest)
      .where(completion_date: date)
      .where('progress >= quests.progress_required')
      .map(&:quest)
  end

  def quest_progress(quest_id, date = Date.current)
    user_quest_completions
      .where(quest_id: quest_id, completion_date: date)
      .pick(:progress) || 0
  end

  # Vérifier si une quête est complétée
  def has_completed_quest?(quest_id, date = Date.current)
    user_quest_completions
      .where(quest_id: quest_id, completion_date: date)
      .where('progress >= (SELECT progress_required FROM quests WHERE quest_id = ?)', quest_id)
      .exists?
  end

  # JWT token generation
  def generate_jwt
    new_jti = SecureRandom.uuid
    
    success = update_column(:current_jti, new_jti)

    token = JWT.encode(
      {
        id: id,
        email: email,
        username: username,
        exp: 60.days.from_now.to_i,
        jti: new_jti
      },
      Rails.application.credentials.devise_jwt_secret_key!
    )
    token
  end

  def invalidate_jwt
    update_column(:current_jti, nil)
  end

  def valid_jti?(token_jti)
    current_jti.present? && token_jti == current_jti
  end

  def on_jwt_dispatch(_token, _payload)
    # Vous pouvez ajouter ici une logique supplémentaire lors de la création du token
  end

  # Premium methods
  def premium?
    isPremium
  end

  def update_premium_status_based_on_subscription
    update(isPremium: stripe_subscription_id.present?)
  end

  # Méthode pour vérifier si l'utilisateur est un administrateur
  def admin?
    is_admin == true
  end

  # Méthode pour promouvoir un utilisateur en administrateur
  def make_admin!
    update(is_admin: true)
  end

  # Méthode pour révoquer les droits d'administrateur
  def revoke_admin!
    update(is_admin: false)
  end

  # Méthode de débogage pour les matchs
  def todays_matches(date = Date.current)
    day_matches = matches.where(created_at: date.beginning_of_day..date.end_of_day)
    
    day_matches
  end

  private

  def set_default_premium_status
    self.isPremium = false
  end

  def ensure_default_level_exp
    self.level ||= 1
    self.experience ||= 0
  end

  def send_welcome_email
    NotificationMailer.welcome_email(self).deliver_later
  end
end
