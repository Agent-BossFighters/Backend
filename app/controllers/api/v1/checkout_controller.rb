require 'net/http'

module Api
  module V1
    class CheckoutController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!

      def create
        begin
          puts "🔵 Début de la création de la session Stripe"

          base_url = ENV['FRONTEND_URL']&.gsub(/\/+$/, '')

          unless base_url
            puts "❌ FRONTEND_URL manquant"
            render json: { error: "Configuration error: FRONTEND_URL missing" }, status: :internal_server_error
            return
          end

          session_params = {
            mode: 'subscription',
            payment_method_types: ['card', 'paypal', 'link'],
            line_items: [{
              price: params[:priceId],
              quantity: 1
            }],
            subscription_data: {
              metadata: {
                user_id: current_user.id
              }
            },
            success_url: "#{base_url}#/payments/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url: "#{base_url}#/payments/cancel",
            allow_promotion_codes: true,
            locale: detect_locale_from_header
          }

          if current_user.stripe_customer_id.present?
            session_params[:customer] = current_user.stripe_customer_id
          else
            session_params[:customer_email] = current_user.email
          end

          session_params.compact!

          puts "📌 Paramètres de la session Stripe : #{session_params.inspect}"

          @session = Stripe::Checkout::Session.create(session_params)

          puts "✅ Session Stripe créée avec succès : #{@session.id}"

          render json: { url: @session.url, session_id: @session.id }, status: :ok
        rescue Stripe::StripeError => e
          puts "❌ Erreur Stripe : #{e.message}"
          render json: { error: e.message }, status: :unprocessable_entity
        rescue => e
          puts "❌ Erreur inconnue : #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def success
        begin
          session_id = params[:session_id]

          unless session_id
            puts "❌ Session ID manquante"
            render json: { success: false, status: 'incomplete', error: 'Session ID missing' }, status: :bad_request
            return
          end

          puts "🔍 Récupération de la session Stripe #{session_id}"
          session = Stripe::Checkout::Session.retrieve({
            id: session_id,
            expand: ['subscription']
          })

          puts "📌 Session récupérée : #{session.inspect}"

          if session.subscription
            puts "📌 Subscription trouvée : #{session.subscription.id}"

            user = User.find_by(email: session.customer_email)

            if user.nil?
              puts "❌ Utilisateur introuvable avec ID #{session.metadata.user_id}"
              render json: { success: false, error: "User not found", status: 'error' }, status: :not_found
              return
            end

            puts "✅ Utilisateur trouvé : #{user.email}"

            success = user.update(
              isPremium: true,
              stripe_customer_id: session.customer,
              stripe_subscription_id: session.subscription.id
            )
            PaymentMailer.payment_succeeded_email(user).deliver_later

            new_token = user.generate_jwt
            puts "🔑 Nouveau token JWT généré"

            render json: {
              success: true,
              status: 'complete',
              current_period_end: Time.at(session.subscription.current_period_end),
              customer_email: session.customer_details&.email,
              user: {
                id: user.id,
                email: user.email,
                username: user.username,
                isPremium: user.isPremium,
                is_admin: user.is_admin
              },
              token: new_token
            }, status: :ok
          else
            puts "⚠️ Subscription non trouvée dans la session"
            render json: {
              success: false,
              status: 'incomplete'
            }, status: :ok
          end
        rescue => e
          puts "❌ Erreur dans success : #{e.message}"
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

      private

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
    end
  end
end
