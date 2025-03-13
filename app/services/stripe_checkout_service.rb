class StripeCheckoutService
  def self.create_session(current_user, price_id, locale = 'en')
    base_url = ENV['FRONTEND_URL']&.gsub(/\/+$/, '')

    unless base_url
      raise StandardError, "Configuration error: FRONTEND_URL missing"
    end

    unless current_user
      raise StandardError, "User not authenticated"
    end

    ensure_stripe_customer(current_user)
    create_checkout_session(current_user, price_id, base_url, locale)
  end

  private

  def self.ensure_stripe_customer(user)
    return if user.stripe_customer_id

    customer = Stripe::Customer.create(
      email: user.email,
      metadata: {
        user_id: user.id
      }
    )

    # Sauvegarder immédiatement le customer_id
    user.update!(stripe_customer_id: customer.id)
    Rails.logger.info "Customer ID saved for user #{user.id}: #{customer.id}"
  end

  def self.create_checkout_session(user, price_id, base_url, locale)
    session_params = {
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      subscription_data: {
        metadata: {
          user_id: user.id
        }
      },
      customer: user.stripe_customer_id,
      success_url: "#{base_url}/payments/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{base_url}/payments/cancel",
      allow_promotion_codes: true,
      locale: locale
    }

    session_params.compact!
    Rails.logger.info "Creating Stripe session with params: #{session_params.inspect}"

    Stripe::Checkout::Session.create(session_params)
  end
end
