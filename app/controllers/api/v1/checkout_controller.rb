module Api
  module V1
    class CheckoutController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, except: [:webhook]

      def create
        begin
          @session = StripeCheckoutService.create_session(
            current_user,
            params[:priceId],
            params[:locale] || detect_locale_from_header
          )
          render json: { url: @session.url, session_id: @session.id }, status: :ok
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def success
        begin
          session = Stripe::Checkout::Session.retrieve({
            id: params[:session_id],
            expand: ['subscription', 'payment_intent']
          })

          if session.subscription && session.payment_intent && session.payment_intent.status == 'succeeded'
            user = User.find(session.metadata.user_id)
            user.update!(stripe_customer_id: session.customer)

            # Force le statut premium à true quand le paiement est réussi
            result = user.force_premium_status!(true)

            render json: {
              success: true,
              status: 'complete',
              user_id: user.id,
              username: user.username,
              email: user.email,
              isPremium: user.isPremium,
              stripe_customer_id: user.stripe_customer_id,
              force_result: result,
              subscription_status: session.subscription.status,
              payment_status: session.payment_intent.status,
              current_period_end: Time.at(session.subscription.current_period_end),
              customer_email: session.customer_details&.email
            }, status: :ok
          else
            render json: {
              success: false,
              status: 'incomplete',
              subscription_status: session.subscription&.status,
              payment_status: session.payment_intent&.status
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

      def test_premium
        user_id = params[:user_id]
        force = params[:force] == 'true'
        status = params[:status] == 'true'
        debug = params[:debug] == 'true'

        user = User.find(user_id)

        if debug
          db_value = ActiveRecord::Base.connection.select_value("SELECT \"isPremium\" FROM users WHERE id = #{user.id}")
          has_active = false

          if user.stripe_customer_id
            begin
              subscriptions = Stripe::Subscription.list(customer: user.stripe_customer_id)
              has_active = subscriptions.data.any? { |sub| sub.status == 'active' }
            rescue => e
            end
          end

          render json: {
            user_id: user.id,
            username: user.username,
            email: user.email,
            isPremium: user.isPremium,
            db_isPremium: db_value,
            stripe_customer_id: user.stripe_customer_id,
            has_active_subscription: has_active,
            diagnostic: true
          }, status: :ok
        elsif force
          result = user.force_premium_status!(status)
          render json: {
            user_id: user.id,
            username: user.username,
            email: user.email,
            isPremium: user.isPremium,
            stripe_customer_id: user.stripe_customer_id,
            force_result: result
          }, status: :ok
        else
          subscriptions = []
          if user.stripe_customer_id
            begin
              subscriptions = Stripe::Subscription.list(customer: user.stripe_customer_id)
            rescue Stripe::StripeError => e
            end
          end

          result = user.update_premium_status!
          render json: {
            user_id: user.id,
            username: user.username,
            email: user.email,
            isPremium: user.isPremium,
            stripe_customer_id: user.stripe_customer_id,
            update_result: result,
            subscriptions: subscriptions.data.map do |sub|
              {
                id: sub.id,
                status: sub.status,
                current_period_end: Time.at(sub.current_period_end),
                cancel_at_period_end: sub.cancel_at_period_end
              }
            end
          }, status: :ok
        end
      end

      def webhook
        payload = request.body.read
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']

        begin
          event = Stripe::Webhook.construct_event(
            payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
          )

          process_stripe_event(event)
          render json: { received: true }
        rescue JSON::ParserError => e
          render json: { error: e.message }, status: :bad_request
        rescue Stripe::SignatureVerificationError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :bad_request
        end
      end

      private

      def process_stripe_event(event)
        Rails.logger.info "Processing Stripe event: #{event.type}"
        case event.type
        when 'checkout.session.completed'
          process_checkout_session_completed(event.data.object)
        when 'payment_intent.succeeded'
          process_payment_intent_succeeded(event.data.object)
        when 'invoice.payment_succeeded'
          process_invoice_payment_succeeded(event.data.object)
        when 'customer.subscription.created'
          process_subscription_created(event.data.object)
        when 'customer.subscription.updated'
          process_subscription_updated(event.data.object)
        when 'customer.subscription.deleted'
          process_subscription_deleted(event.data.object)
        when 'customer.updated'
          process_customer_updated(event.data.object)
        when 'payment_method.attached'
          process_payment_method_attached(event.data.object)
        end
      end

      def process_checkout_session_completed(session)
        Rails.logger.info "Processing checkout session completed: #{session.id}"
        user = User.find(session.metadata.user_id)
        return unless user

        # Met à jour le customer_id
        if user.stripe_customer_id != session.customer
          user.update!(stripe_customer_id: session.customer)
        end
      end

      def process_payment_intent_succeeded(payment_intent)
        Rails.logger.info "Processing payment intent succeeded: #{payment_intent.id}"
        return unless payment_intent.invoice

        invoice = Stripe::Invoice.retrieve(payment_intent.invoice)
        subscription = invoice.subscription
        return unless subscription

        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
        PaymentMailer.payment_success_email(user).deliver_later if user.isPremium
      end

      def process_invoice_payment_succeeded(invoice)
        Rails.logger.info "Processing invoice payment succeeded: #{invoice.id}"
        return unless invoice.subscription

        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def process_subscription_created(subscription)
        Rails.logger.info "Processing subscription created: #{subscription.id}"
        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def process_subscription_updated(subscription)
        Rails.logger.info "Processing subscription updated: #{subscription.id}"
        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def process_subscription_deleted(subscription)
        Rails.logger.info "Processing subscription deleted: #{subscription.id}"
        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def process_customer_updated(customer)
        Rails.logger.info "Processing customer updated: #{customer.id}"
        user = User.find_by(stripe_customer_id: customer.id)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def process_payment_method_attached(payment_method)
        Rails.logger.info "Processing payment method attached: #{payment_method.id}"
        customer = payment_method.customer
        return unless customer

        user = User.find_by(stripe_customer_id: customer)
        return unless user

        Rails.logger.info "Updating premium status for user #{user.id}"
        user.update_premium_status!
      end

      def detect_locale_from_header
        accept_language = request.headers['Accept-Language']
        return 'en' unless accept_language

        preferred_language = accept_language.split(',').first&.split(';')&.first&.downcase
        return 'en' unless preferred_language

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

      def log_request_details
        Rails.logger.info "Request Headers: #{request.headers.to_h.select { |k, _| k.start_with?('HTTP_') }}"
        Rails.logger.info "Request Parameters: #{params.inspect}"
        Rails.logger.info "Current User: #{current_user&.id}"
      end
    end
  end
end
