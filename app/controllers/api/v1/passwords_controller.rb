module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      skip_before_action :authenticate_user!
      respond_to :json

      def create
        Rails.logger.info "Password reset requested with params: #{params.inspect}"

        # Vérifier si l'email existe
        email = params[:email] || params.dig(:user, :email)
        Rails.logger.info "Looking for user with email: #{email}"

        user = User.find_by(email: email)
        if user.nil?
          Rails.logger.error "User not found with email: #{email}"
          return render json: { error: 'Email not found' }, status: :not_found
        end

        Rails.logger.info "User found: #{user.inspect}"

        # Envoyer les instructions de réinitialisation
        self.resource = resource_class.send_reset_password_instructions({ email: email })
        yield resource if block_given?

        if successfully_sent?(resource)
          Rails.logger.info "Reset password instructions sent successfully to #{email}"
          render json: { message: 'Reset password instructions have been sent to your email.' }, status: :ok
        else
          Rails.logger.error "Failed to send reset password instructions. Errors: #{resource.errors.full_messages}"
          render json: { error: resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        Rails.logger.info "Updating password with params: #{params.inspect}"
        self.resource = resource_class.reset_password_by_token(resource_params)
        yield resource if block_given?

        if resource.errors.empty?
          resource.unlock_access! if unlockable?(resource)
          render json: { message: 'Password has been reset successfully.' }, status: :ok
        else
          Rails.logger.error "Failed to reset password. Errors: #{resource.errors.full_messages}"
          render json: { error: resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def resource_params
        # Gérer les deux formats possibles de paramètres
        if params[:user].present?
          params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
        else
          params.permit(:email, :password, :password_confirmation, :reset_password_token)
        end
      end
    end
  end
end
