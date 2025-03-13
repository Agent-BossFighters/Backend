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

  def update_premium_status!
    Rails.logger.info "=== UPDATING PREMIUM STATUS ==="
    Rails.logger.info "User ID: #{id}"
    Rails.logger.info "Current isPremium: #{isPremium}"
    Rails.logger.info "Stripe Customer ID: #{stripe_customer_id}"

    return false unless stripe_customer_id

    begin
      # Récupérer le client Stripe
      customer = Stripe::Customer.retrieve(stripe_customer_id)
      Rails.logger.info "Customer retrieved: #{customer.id}"

      # Récupérer les abonnements séparément
      subscriptions = Stripe::Subscription.list(customer: stripe_customer_id)
      Rails.logger.info "Found #{subscriptions.data.length} subscriptions"

      # Vérifier s'il y a des abonnements actifs
      has_active_subscription = subscriptions.data.any? { |sub| sub.status == 'active' }
      Rails.logger.info "Has active subscription: #{has_active_subscription}"

      # Log des détails des abonnements
      subscriptions.data.each do |sub|
        Rails.logger.info "Subscription #{sub.id}:"
        Rails.logger.info "  Status: #{sub.status}"
        Rails.logger.info "  Current Period End: #{Time.at(sub.current_period_end)}"
        Rails.logger.info "  Cancel At Period End: #{sub.cancel_at_period_end}"
      end

      # Mettre à jour seulement si nécessaire
      if self.isPremium != has_active_subscription
        Rails.logger.info "Updating isPremium from #{self.isPremium} to #{has_active_subscription}"
        # Utiliser update_column pour contourner les validations et callbacks
        result = update_column(:isPremium, has_active_subscription)
        Rails.logger.info "Update result: #{result}"
        return result
      end

      Rails.logger.info "No update needed, current status matches"
      return true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error updating premium status: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return false
    rescue => e
      Rails.logger.error "Error updating premium status: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return false
    end
  end

  # Cette méthode est maintenant un simple alias pour update_premium_status!
  def sync_premium_status!
    update_premium_status!
  end

  # Méthode de test pour forcer la mise à jour du statut premium
  def force_premium_status!(status)
    Rails.logger.info "=== FORCE PREMIUM STATUS ==="
    Rails.logger.info "User ID: #{id}"
    Rails.logger.info "Current isPremium: #{isPremium}"
    Rails.logger.info "New status: #{status}"

    # Essayer d'abord avec update_column
    begin
      result = update_column(:isPremium, status)
      Rails.logger.info "Force update with update_column result: #{result}"
    rescue => e
      Rails.logger.error "Error with update_column: #{e.message}"
      # Si update_column échoue, essayer avec update_attribute
      begin
        result = update_attribute(:isPremium, status)
        Rails.logger.info "Force update with update_attribute result: #{result}"
      rescue => e
        Rails.logger.error "Error with update_attribute: #{e.message}"
        # Dernier recours: SQL direct
        begin
          ActiveRecord::Base.connection.execute("UPDATE users SET \"isPremium\" = #{status} WHERE id = #{id}")
          Rails.logger.info "Force update with direct SQL executed"
          result = true
        rescue => e
          Rails.logger.error "Error with direct SQL: #{e.message}"
          result = false
        end
      end
    end

    # Vérifier que la mise à jour a bien été prise en compte
    reload
    Rails.logger.info "After reload isPremium: #{isPremium}"
    Rails.logger.info "isPremium matches expected status: #{isPremium == status}"

    return result
  end

  private

  def set_default_premium_status
    self.isPremium = false
  end

  def send_welcome_email
    NotificationMailer.welcome_email(self).deliver_later
  end
end
