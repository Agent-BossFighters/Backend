module Api
  module V1
    class WebhookController < ApplicationController
      skip_before_action :verify_authenticity_token

      def webhook
        puts "🔵 Webhook Stripe reçu !"

        payload = request.body.read
        sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

        begin
          event = Stripe::Webhook.construct_event(
            payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
          )

          puts "🟢 Event Stripe détecté : #{event[:type]}"

          case event[:type]
          when "checkout.session.completed"
            handle_subscription_created(event[:data][:object])
          when "customer.subscription.created"
            handle_subscription_created(event[:data][:object])
          when "customer.subscription.updated"
            handle_subscription_updated(event[:data][:object])
          when "customer.subscription.deleted"
            handle_subscription_deleted(event[:data][:object])
          when "invoice.payment_succeeded"
            handle_payment_succeeded(event[:data][:object])
          when "invoice.payment_failed"
            handle_payment_failed(event[:data][:object])
          when "invoice.payment_action_required"
            handle_payment_action_required(event[:data][:object])
          when "crypto.onramp.session.completed"
            handle_crypto_onramp_completed(event[:data][:object])
          when "crypto.onramp.session.failed"
            handle_crypto_onramp_failed(event[:data][:object])
          else
            puts "⚠️ Webhook ignoré : #{event[:type]}"
          end

          render json: { received: true }, status: :ok
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
          isPremium: true
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

        if session[:customer].present?
          user = User.find_by(stripe_customer_id: session[:customer])
          if user
            puts "📝 Transaction enregistrée pour l'utilisateur : #{user.email}"
          end
        end
      end

      def handle_crypto_onramp_failed(session)
        puts "❌ Échec de la transaction crypto onramp : #{session[:id]}"

        if session[:customer].present?
          user = User.find_by(stripe_customer_id: session[:customer])
          if user
            puts "⚠️ Notification d'échec envoyée à : #{user.email}"
          end
        end
      end
    end
  end
end
