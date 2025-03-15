class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  before_action :authenticate_user!

  private

  def authenticate_user!
    return if current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
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
      @current_user = User.find(decoded.first['id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end

  def authenticate_admin!
    authenticate_user!
    unless current_user&.admin?
      render json: { error: 'Accès refusé. Droits d\'administrateur requis.' }, status: :forbidden
    end
  end
end
