class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.find_by(email: sign_in_params[:email])

    if user&.valid_password?(sign_in_params[:password])
      token = user.generate_jwt
      render json: {
        token: token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email
        }
      }
    else
      render json: { errors: { "email or password" => [ "is invalid" ] } }, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.invalidate_jwt
    head :no_content
  end

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end
