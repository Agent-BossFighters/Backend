class Api::V1::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: :create
  respond_to :json
  skip_before_action :verify_authenticity_token

  def create
    user = User.find_by(email: sign_in_params[:email])
    if user&.valid_password?(sign_in_params[:password])
      
      # Utiliser la méthode generate_jwt du modèle User au lieu de créer le JWT directement
      token = user.generate_jwt

      render json: {
        user: user,
        token: token,
        message: 'Logged in successfully'
      }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  def destroy
    # Utiliser invalidate_jwt pour nettoyer le JTI
    if current_user
      current_user.invalidate_jwt
      Rails.logger.info "Invalidated JWT for user: #{current_user.email}"
    end
    
    render json: { message: 'Logged out successfully' }, status: :ok
  end

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end
