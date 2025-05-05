module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    unless current_user&.admin?
      render json: { error: "Accès refusé. Droits d'administrateur requis." }, status: :forbidden
    end
  end
end
