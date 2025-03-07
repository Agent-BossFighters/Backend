class CheckoutController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, except: [:webhook]

  def create
    begin
      base_url = ENV['FRONTEND_URL']&.gsub(/\/+$/, '')

      unless base_url
        render json: { error: "Configuration error: FRONTEND_URL missing" }, status: :internal_server_error
        return
      end

      @session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'usd',
            unit_amount: 1199,
            product_data: {
              name: 'Monthly Premium Access',
              description: 'Access to Monthly data and premium features'
            },
          },
          quantity: 1
        }],
        mode: 'payment',
        metadata: { user_id: current_user.id },
        success_url: "#{base_url}/payments/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{base_url}/payments/cancel"
      )

      if params[:redirect] == 'true'
        redirect_to @session.url, allow_other_host: true
      else
        render json: { url: @session.url, session_id: @session.id }, status: :ok
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def success
    begin
      session_id = params[:session_id]

      unless session_id
        render json: { success: false, status: 'incomplete', error: 'Session ID missing' }, status: :bad_request
        return
      end

      session = Stripe::Checkout::Session.retrieve(session_id)
      payment_intent = Stripe::PaymentIntent.retrieve(session.payment_intent)

      if payment_intent.status == 'succeeded'
        user = User.find(session.metadata.user_id)
        if user&.update(is_premium: true)
          # Envoyer l'email de confirmation
          PaymentMailer.payment_success_email(user).deliver_later
        end

        render json: {
          success: true,
          status: 'complete',
          payment_status: payment_intent.status,
          amount_total: session.amount_total / 100.0,
          customer_email: session.customer_details&.email
        }, status: :ok
      else
        render json: {
          success: false,
          status: 'incomplete',
          payment_status: payment_intent.status
        }, status: :ok
      end
    rescue => e
      render json: { success: false, error: e.message, status: 'error' }, status: :unprocessable_entity
    end
  end

  def cancel
    render json: {
      success: false,
      status: 'cancelled',
      message: 'Payment cancelled by user'
    }, status: :ok
  end

  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
      )

      if event.type == 'checkout.session.completed'
        session = event.data.object
        user = User.find(session.metadata.user_id)
        if user&.update(is_premium: true)
          # Envoyer l'email de confirmation via le webhook
          PaymentMailer.payment_success_email(user).deliver_later
        end
      end

      render json: { received: true }
    rescue JSON::ParserError => e
      render json: { error: e.message }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      render json: { error: e.message }, status: :bad_request
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def authenticate_user!
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
end
