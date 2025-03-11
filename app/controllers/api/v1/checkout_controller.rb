module Api
  module V1
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

          session_params = {
            mode: 'subscription',
            payment_method_types: ['card'],
            line_items: [{
              price: params[:priceId],
              quantity: 1
            }],
            subscription_data: {
              metadata: {
                user_id: current_user.id
              }
            },
            customer: current_user.stripe_customer_id,
            customer_email: current_user.email,
            success_url: "#{base_url}/payments/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url: "#{base_url}/payments/cancel",
            allow_promotion_codes: true,
            locale: 'en'
          }

          session_params.compact!

          @session = Stripe::Checkout::Session.create(session_params)
          render json: { url: @session.url, session_id: @session.id }, status: :ok
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def success
        begin
          session_id = params[:session_id]

          unless session_id
            render json: { success: false, status: 'incomplete', error: 'Session ID missing' }, status: :bad_request
            return
          end

          session = Stripe::Checkout::Session.retrieve({
            id: session_id,
            expand: ['subscription']
          })

          if session.subscription
            user = User.find(session.metadata.user_id)
            if user&.update(
              is_premium: true,
              stripe_customer_id: session.customer,
              stripe_subscription_id: session.subscription.id
            )
              PaymentMailer.payment_success_email(user).deliver_later
            end

            render json: {
              success: true,
              status: 'complete',
              current_period_end: Time.at(session.subscription.current_period_end),
              customer_email: session.customer_details&.email
            }, status: :ok
          else
            render json: {
              success: false,
              status: 'incomplete'
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

          case event.type
          when 'customer.subscription.created'
            handle_subscription_created(event.data.object)
          when 'customer.subscription.updated'
            handle_subscription_updated(event.data.object)
          when 'customer.subscription.deleted'
            handle_subscription_deleted(event.data.object)
          when 'invoice.payment_succeeded'
            handle_payment_succeeded(event.data.object)
          when 'invoice.payment_failed'
            handle_payment_failed(event.data.object)
          when 'invoice.payment_action_required'
            handle_payment_action_required(event.data.object)
          end

          render json: { received: true }
        rescue JSON::ParserError => e
          render json: { error: e.message }, status: :bad_request
        rescue Stripe::SignatureVerificationError => e
          render json: { error: e.message }, status: :bad_request
        end
      end

      private

      def handle_subscription_created(subscription)
        user = User.find(subscription.metadata.user_id)
        return unless user

        user.update(
          stripe_customer_id: subscription.customer,
          stripe_subscription_id: subscription.id,
          is_premium: true
        )
        PaymentMailer.subscription_created_email(user).deliver_later
      end

      def handle_subscription_updated(subscription)
        user = User.find(subscription.metadata.user_id)
        return unless user

        user.update(
          stripe_customer_id: subscription.customer,
          stripe_subscription_id: subscription.id,
          is_premium: true
        )
        PaymentMailer.subscription_updated_email(user).deliver_later
      end

      def handle_subscription_deleted(subscription)
        user = User.find_by(stripe_subscription_id: subscription.id)
        return unless user

        user.update(is_premium: false)
        PaymentMailer.payment_canceled_email(user).deliver_later
      end

      def handle_payment_succeeded(invoice)
        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        PaymentMailer.payment_succeeded_email(user).deliver_later
      end

      def handle_payment_failed(invoice)
        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        PaymentMailer.payment_failed_email(user).deliver_later
        user.update(is_premium: false) if invoice.attempt_count > 3
      end

      def handle_payment_action_required(invoice)
        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        PaymentMailer.payment_action_required_email(user).deliver_later
      end

      def detect_locale_from_header
        accept_language = request.headers['Accept-Language']
        return 'en' unless accept_language

        # Extraire la première langue préférée
        preferred_language = accept_language.split(',').first&.split(';')&.first&.downcase
        return 'en' unless preferred_language

        # Mapper les codes de langue courants vers les locales Stripe
        case preferred_language
        when 'fr', 'fr-fr'
          'fr'
        when 'zh', 'zh-cn'
          'zh'
        else
          'en'
        end
      end

      def authenticate_user!
        unless current_user
          render json: { error: 'Authentication required' }, status: :unauthorized
        end
      end
    end
  end
end
