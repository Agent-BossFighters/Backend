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
        
        # Méthode pour invalider les caches après les actions d'administration
        # Cette méthode peut être appelée par tous les contrôleurs d'administration
        def invalidate_admin_caches(resource_type = nil)
          # Invalider le cache des taux de monnaie
          DataLab::CurrencyRatesService.invalidate_cache if defined?(DataLab::CurrencyRatesService)
          
          # Invalider tous les caches data_lab pour tous les utilisateurs
          Rails.cache.delete_matched("data_lab/*")
          
          # Selon le type de ressource modifiée, on peut invalider des caches spécifiques
          case resource_type
          when :items
            # Caches spécifiques aux items
            Rails.cache.delete_matched("data_lab/slots/*")
            Rails.cache.delete_matched("items/*")
          when :users
            # Caches spécifiques aux utilisateurs
            Rails.cache.delete_matched("users/*")
          when :matches
            # Caches spécifiques aux matches
            Rails.cache.delete_matched("matches/*")
          end
          
          # Log pour debug
          Rails.logger.info("Admin cache invalidated for: #{resource_type || 'all resources'}")
        end
      end
    end
  end
end
