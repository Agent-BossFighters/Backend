class Api::V1::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :create ]
  respond_to :json
  skip_before_action :verify_authenticity_token

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: {
          user: resource,
          token: request.env["warden-jwt_auth.token"]
        }
      }
    else
      render json: {
        status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :username)
  end
end
