require 'net/http'

module Api
  module V1
    class CheckoutController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :authenticate_user!, except: [:webhook, :create_crypto_onramp]

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
            # customer: current_user.stripe_customer_id,
            # customer_email: current_user.email,
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

      def create_crypto_onramp
        begin
          puts "🔵 Début de la création de l'URL de redirection Crypto Onramp"

          # Base URL for Stripe's crypto onramp
          base_url = "https://crypto.link.com"

          # Initialize params hash for validated parameters
          validated_params = {}

          # Validate and process wallet addresses
          if params[:wallet_addresses].present? && params[:wallet_addresses].is_a?(Hash)
            validated_params[:wallet_addresses] = params[:wallet_addresses].transform_values(&:to_s)
          end

          # Validate and add supported parameters
          supported_params = {
            destination_network: params[:destination_network],
            destination_currency: params[:destination_currency],
            destination_amount: params[:destination_amount],
            source_currency: params[:source_currency],
            source_amount: params[:source_amount],
            transaction_id: params[:transaction_id],
            customer_email: params[:customer_email]
          }

          # Add non-nil parameters to validated params
          supported_params.each do |key, value|
            validated_params[key] = value.to_s if value.present?
          end

          # Build query string from validated parameters
          query_params = []

          # Handle wallet addresses specially
          if validated_params[:wallet_addresses].present?
            validated_params[:wallet_addresses].each do |network, address|
              query_params << "wallet_addresses[#{CGI.escape(network)}]=#{CGI.escape(address)}"
            end
          end

          # Add other parameters
          validated_params.except(:wallet_addresses).each do |key, value|
            query_params << "#{key}=#{CGI.escape(value)}"
          end

          # Construct final URL
          redirect_url = query_params.empty? ? base_url : "#{base_url}?#{query_params.join('&')}"

          puts "✅ URL de redirection Crypto Onramp générée : #{redirect_url}"

          render json: {
            success: true,
            redirectUrl: redirect_url
          }, status: :ok

        rescue => e
          puts "❌ Erreur lors de la création de l'URL Crypto Onramp: #{e.message}"
          render json: {
            success: false,
            error: e.message
          }, status: :internal_server_error
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

            render json: {
              success: true,
              status: 'complete',
              current_period_end: Time.at(session.subscription.current_period_end),
              customer_email: session.customer_details&.email
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

      def webhook
        puts "🔵 Webhook Stripe reçu !"

        payload = request.body.read
        #sig_header = request.env['HTTP_STRIPE_SIGNATURE']

        begin
          # event = Stripe::Webhook.construct_event(
          #   payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
          # )
          event = JSON.parse(payload, symbolize_names: true)

          puts "🟢 Event Stripe détecté : #{event[:type]}"

          case event[:type]
          when 'checkout.session.completed'
            handle_subscription_created(event[:data][:object])
          when 'customer.subscription.created'
            handle_subscription_created(event[:data][:object])
          when 'customer.subscription.updated'
            handle_subscription_updated(event[:data][:object])
          when 'customer.subscription.deleted'
            handle_subscription_deleted(event[:data][:object])
          when 'invoice.payment_succeeded'
            handle_payment_succeeded(event[:data][:object])
          when 'invoice.payment_failed'
            handle_payment_failed(event[:data][:object])
          when 'invoice.payment_action_required'
            handle_payment_action_required(event[:data][:object])
          # Ajout des événements crypto
          when 'crypto.onramp.session.completed'
            handle_crypto_onramp_completed(event[:data][:object])
          when 'crypto.onramp.session.failed'
            handle_crypto_onramp_failed(event[:data][:object])
          else
            puts "⚠️ Webhook ignoré : #{event[:type]}"
          end

          render json: { received: true }
        rescue JSON::ParserError => e
          puts "❌ Erreur JSON : #{e.message}"
          render json: { error: e.message }, status: :bad_request
        rescue Stripe::SignatureVerificationError => e
          puts "❌ Erreur Signature Stripe : #{e.message}"
          render json: { error: e.message }, status: :bad_request
        end
      end

      private

      def handle_subscription_created(subscription)
        puts "🔍 Webhook Stripe reçu !"
        puts "📌 ID abonnement: #{subscription[:id]}"
        puts "📌 ID client: #{subscription[:customer]}"
        puts "📌 Metadata: #{subscription[:metadata]}"

        user = User.find_by(id: subscription[:metadata][:user_id])

        if user.nil?
          puts "❌ Erreur : Utilisateur introuvable"
          return
        end

        puts "✅ Utilisateur trouvé : #{user.email}"

        user.update(
          stripe_customer_id: subscription[:customer],
          stripe_subscription_id: subscription[:id],
          isPremium: true
        )
        PaymentMailer.payment_succeeded_email(user).deliver_later

        puts "🎉 `isPremium` activé pour #{user.email} ✅"
      end

      def handle_subscription_updated(subscription)
        puts "🔄 Mise à jour de l'abonnement : #{subscription[:id]}"

        user = User.find_by(id: subscription[:metadata][:user_id])
        if user.nil?
          puts "❌ Utilisateur introuvable"
          return
        end

        puts "✅ Utilisateur trouvé : #{user.email}"
        user.update(
          stripe_customer_id: subscription[:customer],
          stripe_subscription_id: subscription[:id],
          isPremium: true  # ✅ Utilise `isPremium` avec la majuscule
        )
        puts "🎉 Abonnement mis à jour pour #{user.email} ✅"

        PaymentMailer.subscription_updated_email(user).deliver_later
      end

      def handle_subscription_deleted(subscription)
        puts "🛑 Abonnement annulé : #{subscription[:id]}"

        user = User.find_by(stripe_subscription_id: subscription[:id])
        if user.nil?
          puts "❌ Utilisateur introuvable"
          return
        end

        puts "✅ Utilisateur trouvé : #{user.email}"
        user.update(isPremium: false)
        puts "⚠️ Abonnement annulé pour #{user.email}"

        PaymentMailer.payment_canceled_email(user).deliver_later
      end

      def handle_payment_succeeded(invoice)
        puts "💰 Paiement réussi : #{invoice[:id]}"

        user = User.find_by(stripe_customer_id: invoice[:customer])
        if user.nil?
          puts "❌ Utilisateur introuvable"
          return
        end

        puts "✅ Utilisateur trouvé : #{user.email}"
        PaymentMailer.payment_succeeded_email(user).deliver_later
      end

      def handle_payment_failed(invoice)
        puts "❌ Échec de paiement : #{invoice[:id]}"

        user = User.find_by(stripe_customer_id: invoice[:customer])
        if user.nil?
          puts "❌ Utilisateur introuvable"
          return
        end

        puts "⚠️ Notification d'échec de paiement pour #{user.email}"
        PaymentMailer.payment_failed_email(user).deliver_later

        if invoice[:attempt_count] > 3
          user.update(isPremium: false)
          puts "⏳ Désactivation de l'abonnement pour #{user.email}"
        end
      end

      def handle_payment_action_required(invoice)
        puts "🔔 Paiement nécessitant une action : #{invoice[:id]}"

        user = User.find_by(stripe_customer_id: invoice[:customer])
        if user.nil?
          puts "❌ Utilisateur introuvable"
          return
        end

        puts "⚠️ Demande d'action envoyée à #{user.email}"
        PaymentMailer.payment_action_required_email(user).deliver_later
      end

      def handle_crypto_onramp_completed(session)
        puts "✅ Transaction crypto onramp complétée : #{session[:id]}"

        # Si l'utilisateur est associé à la session
        if session[:customer].present?
          user = User.find_by(stripe_customer_id: session[:customer])
          if user
            # Vous pouvez ajouter ici la logique pour mettre à jour l'utilisateur
            # Par exemple, enregistrer la transaction dans votre base de données
            puts "📝 Transaction enregistrée pour l'utilisateur : #{user.email}"
          end
        end
      end

      def handle_crypto_onramp_failed(session)
        puts "❌ Échec de la transaction crypto onramp : #{session[:id]}"

        if session[:customer].present?
          user = User.find_by(stripe_customer_id: session[:customer])
          if user
            # Vous pouvez ajouter ici la logique pour notifier l'utilisateur
            puts "⚠️ Notification d'échec envoyée à : #{user.email}"
          end
        end
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
