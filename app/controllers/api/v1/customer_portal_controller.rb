module Api
  module V1
    class CustomerPortalController < ApplicationController
      before_action :authenticate_user!

      def create
        # Création d'une session du portail client
        portal_session = Stripe::BillingPortal::Session.create({
          customer: current_user.stripe_customer_id,
          return_url: ENV["FRONTEND_URL"],
          configuration: {
            features: {
              subscription_cancel: { enabled: true },
              payment_method_update: { enabled: true },
              invoice_history: { enabled: true }
            }
          },
          locale: "en"
        })

        # Redirection vers le portail client
        render json: { url: portal_session.url }, status: :ok
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_user!
        unless current_user
          render json: { error: "Authentication required" }, status: :unauthorized
        end
      end
    end
  end
end
