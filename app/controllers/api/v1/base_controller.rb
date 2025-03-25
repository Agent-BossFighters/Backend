class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    render json: {
      status: 404,
      error: :not_found,
      message: "Resource not found"
    }, status: :not_found
  end

  def bad_request(e)
    render json: {
      status: 400,
      error: :bad_request,
      message: e.message
    }, status: :bad_request
  end

  def authenticate_user!
    Rails.logger.info "Authorization Header: #{request.headers['Authorization']}"

    if current_user
      Rails.logger.info "User authenticated: #{current_user.id}"
      return true
    end

    Rails.logger.error "Authentication failed"
    render json: {
      error: 'Invalid session. Please reconnect.',
      message: 'Invalid or expired session'
    }, status: :unauthorized
  end

  def isPremium_user!

    if current_user.isPremium
      Rails.logger.info "User is premium: #{current_user.id}"
      return true
    end

    Rails.logger.error "Authentication failed"
    render json: {
      error: 'Unauthorized',
      message: 'User need Premium to access this feature'
    }, status: :unauthorized
  end

  def current_user
    return @current_user if defined?(@current_user)

    header = request.headers['Authorization']
    return nil unless header

    token = header.split(' ').last
    begin
      decoded = JWT.decode(
        token,
        Rails.application.credentials.devise_jwt_secret_key!,
        true,
        algorithm: 'HS256'
      )
      
      user = User.find(decoded.first['id'])
      token_jti = decoded.first['jti']
      
      # Vérifier le JTI du token
      if user.valid_jti?(token_jti)
        @current_user = user
      else
        Rails.logger.error "Invalid JTI for user #{user.id}: #{token_jti}"
        @current_user = nil
      end
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      nil
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "User not found: #{e.message}"
      nil
    end
  end
end
