module Api
  module V1
    class DonationController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user! # Require authentication for donations

      def create
        begin
          puts "🔵 Starting donation session creation"

          # Extract amount from params, default to nil if not present
          amount = if params[:amount].present?
            params[:amount].to_i
          elsif params[:donation] && params[:donation][:amount].present?
            params[:donation][:amount].to_i
          else
            nil
          end

          unless amount
            render json: { error: "Amount is required" }, status: :unprocessable_entity
            return
          end

          if amount < 100  # Minimum 1€ (100 cents)
            render json: { error: "Minimum amount is 1€" }, status: :unprocessable_entity
            return
          end

          base_url = ENV['FRONTEND_URL']&.gsub(/\/+$/, '')

          unless base_url
            puts "❌ FRONTEND_URL missing"
            render json: { error: "Configuration error: FRONTEND_URL missing" }, status: :internal_server_error
            return
          end

          session_params = {
            mode: 'payment',
            payment_method_types: ['card'],
            billing_address_collection: 'auto',  # Make postal code optional
            line_items: [{
              price_data: {
                currency: 'eur',
                product: ENV['STRIPE_DONATION_PRODUCT_ID'],
                unit_amount: amount,
              },
              quantity: 1
            }],
            metadata: {
              user_id: current_user.id,
              donation: true
            },
            success_url: "#{base_url}/payments/donations/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url: "#{base_url}/payments/cancel",
            locale: params[:locale] || detect_locale_from_header
          }

          # Add user's Stripe information
          if current_user.stripe_customer_id.present?
            session_params[:customer] = current_user.stripe_customer_id
          else
            session_params[:customer_email] = current_user.email
          end

          session_params.compact!

          puts "📌 Donation session parameters: #{session_params.inspect}"

          @session = Stripe::Checkout::Session.create(session_params)

          puts "✅ Donation session created successfully: #{@session.id}"

          render json: { url: @session.url, session_id: @session.id }, status: :ok
        rescue Stripe::StripeError => e
          puts "❌ Stripe Error: #{e.message}"
          render json: { error: e.message }, status: :unprocessable_entity
        rescue => e
          puts "❌ Unknown Error: #{e.message}"
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def success
        begin
          session_id = params[:session_id]

          unless session_id
            puts "❌ Session ID missing"
            render json: { success: false, error: 'Session ID missing' }, status: :bad_request
            return
          end

          puts "🔍 Retrieving donation session #{session_id}"
          session = Stripe::Checkout::Session.retrieve(session_id)

          if session.payment_status == 'paid'
            puts "💝 Donation received successfully"

            user = User.find_by(id: session.metadata.user_id)

            if user
              PaymentMailer.donation_thank_you_email(user).deliver_later
              new_token = user.generate_jwt
              puts "🔑 New JWT token generated"

              render json: {
                success: true,
                status: 'complete',
                amount: session.amount_total,
                customer_email: session.customer_details&.email,
                token: new_token,
                user: {
                  id: user.id,
                  email: user.email,
                  username: user.username,
                  isPremium: user.isPremium,
                  is_admin: user.is_admin
                }
              }, status: :ok
            else
              render json: {
                success: true,
                status: 'complete',
                amount: session.amount_total,
                customer_email: session.customer_details&.email
              }, status: :ok
            end
          else
            puts "⚠️ Donation payment not completed"
            render json: {
              success: false,
              status: 'incomplete'
            }, status: :ok
          end
        rescue => e
          puts "❌ Error in success: #{e.message}"
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end

      def cancel
        render json: {
          success: false,
          status: 'cancelled',
          message: 'Donation cancelled by user'
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
    end
  end
end
