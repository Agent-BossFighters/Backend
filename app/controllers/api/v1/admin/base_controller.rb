module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        include AdminAuthorization
        
        before_action :authenticate_user!
        before_action :require_admin!
        
        private
        
        def require_admin!
          unless current_user&.admin?
            render json: { error: "Accès non autorisé" }, status: :forbidden
            return
          end
        end
      end
    end
  end
end
