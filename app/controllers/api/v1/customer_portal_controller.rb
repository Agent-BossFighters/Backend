module Api
  module V1
    class CustomerPortalController < ApplicationController
      before_action :authenticate_user!

      def create
        # Vérification que l'utilisateur a un customer_id
        unless current_user.stripe_customer_id
          return render json: { error: 'No Stripe customer ID found' }, status: :unprocessable_entity
        end

        begin
          # Utilisation de l'URL de retour fournie ou de l'URL par défaut
          return_url = params[:returnUrl] || ENV['FRONTEND_URL']

          portal_session = Stripe::BillingPortal::Session.create({
            customer: current_user.stripe_customer_id,
            return_url: return_url,
            configuration: {
              features: {
                subscription_cancel: { enabled: true },
                payment_method_update: { enabled: true },
                invoice_history: { enabled: true }
              }
            },
            locale: 'en'
          })

          render json: { url: portal_session.url }, status: :ok
        rescue Stripe::StripeError => e
          Rails.logger.error "Stripe error: #{e.message}"
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      private

      def authenticate_user!
        unless current_user
          render json: { error: 'Authentication required' }, status: :unauthorized
        end
      end
    end
  end
end
