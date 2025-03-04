class CheckoutController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, except: [:webhook]

  def test_stripe
    begin
      Stripe::PaymentIntent.list(limit: 1)
      render json: { status: 'success', message: 'Stripe est correctement configuré!' }
    rescue Stripe::AuthenticationError => e
      render json: { status: 'error', message: 'Erreur d\'authentification Stripe. Vérifiez vos clés API.' }, status: :unauthorized
    rescue => e
      render json: { status: 'error', message: e.message }, status: :internal_server_error
    end
  end

  def create
    begin
      base_url = params[:success_url]&.gsub(/\/+$/, '') || ENV['FRONTEND_URL']&.gsub(/\/+$/, '')

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
        metadata: {
          user_id: current_user.id
        },
        success_url: "#{base_url}/payments/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{base_url}/payments/cancel"
      )

      Rails.logger.info "Session Stripe créée avec succès: #{@session.id}"

      # Au lieu de renvoyer juste l'URL, on peut rediriger directement
      if params[:redirect] == 'true'
        redirect_to @session.url, allow_other_host: true
      else
        render json: {
          url: @session.url,
          session_id: @session.id
        }, status: :ok
      end
    rescue => e
      Rails.logger.error "Stripe Error: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def success
    begin
      session_id = params[:session_id]

      unless session_id
        Rails.logger.error "Pas de session_id fourni"
        render json: {
          success: false,
          status: 'incomplete',
          error: 'Session ID manquant'
        }, status: :bad_request
        return
      end

      session = Stripe::Checkout::Session.retrieve(session_id)
      payment_intent = Stripe::PaymentIntent.retrieve(session.payment_intent)
      Rails.logger.info "Vérification du paiement - Session ID: #{session_id}, Status: #{payment_intent.status}"

      if payment_intent.status == 'succeeded'
        # Met à jour le statut premium de l'utilisateur
        user = User.find(session.metadata.user_id)
        if user
          user.update(is_premium: true)
          Rails.logger.info "Statut premium mis à jour pour l'utilisateur #{user.id}"
        end

        render json: {
          success: true,
          status: 'complete',
          payment_status: payment_intent.status,
          amount_total: session.amount_total / 100.0,
          customer_email: session.customer_details&.email
        }, status: :ok
      else
        Rails.logger.warn "Paiement incomplet - Status: #{payment_intent.status}"
        render json: {
          success: false,
          status: 'incomplete',
          payment_status: payment_intent.status
        }, status: :ok
      end
    rescue => e
      Rails.logger.error "Erreur lors de la vérification: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error: e.message,
        status: 'error'
      }, status: :unprocessable_entity
    end
  end

  def cancel
    Rails.logger.info "Paiement annulé par l'utilisateur"
    render json: {
      success: false,
      status: 'cancelled',
      message: 'Paiement annulé par l\'utilisateur'
    }, status: :ok
  end

  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
      )

      Rails.logger.info "=== Webhook Stripe reçu ==="
      Rails.logger.info "Type: #{event.type}"

      case event.type
      when 'checkout.session.completed'
        session = event.data.object
        Rails.logger.info "Session complétée pour l'utilisateur #{session.metadata.user_id}"
        user = User.find(session.metadata.user_id)
        if user
          user.update(is_premium: true)
          Rails.logger.info "Utilisateur #{user.id} mis à jour en premium"
        else
          Rails.logger.error "Utilisateur non trouvé: #{session.metadata.user_id}"
        end
      end

      render json: { received: true }
    rescue JSON::ParserError => e
      Rails.logger.error "Erreur de parsing JSON: #{e.message}"
      render json: { error: e.message }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Erreur de signature Stripe: #{e.message}"
      render json: { error: e.message }, status: :bad_request
    rescue => e
      Rails.logger.error "Erreur webhook: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def authenticate_user!
    unless current_user
      Rails.logger.error "Tentative d'accès non authentifiée"
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end
  end
end
