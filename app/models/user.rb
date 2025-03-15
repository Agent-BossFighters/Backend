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

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  # Callbacks
  before_create :set_default_premium_status
  after_create :send_welcome_email

  # JWT token generation
  def generate_jwt
    JWT.encode(
      {
        id: id,
        email: email,
        username: username,
        exp: 60.days.from_now.to_i
      },
      Rails.application.credentials.devise_jwt_secret_key!
    )
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

  private

  def set_default_premium_status
    self.isPremium = false
  end

  def send_welcome_email
    NotificationMailer.welcome_email(self).deliver_later
  end
end
