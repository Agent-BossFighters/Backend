Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      devise_for :users,
        path: '',
        path_names: {
          sign_in: 'login',
          sign_out: 'logout',
          registration: 'signup'
        },
        controllers: {
          sessions: 'api/v1/sessions',
          registrations: 'api/v1/registrations'
        },
        defaults: { format: :json }

      # Routes publiques pour les currencies et currency_packs
      resources :currencies, only: [:index, :show]
      resources :currency_packs, only: [:index, :show]

      resources :users, only: [:show, :update, :destroy] do
        collection do
          patch 'tactics', to: 'users#update_tactics'
          get 'flex_packs', to: 'users#get_flex_packs'
          patch 'level_exp', to: 'users#update_level_exp'
        end
        
        member do
          get 'xp', to: 'users#get_xp'
        end
      end

      resources :quests, only: [:index, :show] do
        member do
          patch 'progress', to: 'quests#update_progress'
        end
      end

      resources :badges do
        collection do
          get 'owned', to: 'badges#owned_badges'
        end
      end
      resources :items
      resources :item_farming
      resources :item_crafting
      resources :item_recharge
      resources :matches, only: [:index, :create, :update, :destroy] do
        collection do
          get 'daily/:date', to: 'matches#daily'
          get 'monthly/:date', to: 'matches#monthly'
          get 'monthly_summary/:date', to: 'matches#monthly_summary'
        end
      end
      resources :player_cycles, only: [:index, :show]
      resources :nfts, only: [:index, :show, :update, :destroy] do
        collection do
          post 'create'
        end
      end
      resources :user_builds do
        collection do
          post 'create'
        end
      end
      resources :slots

      resources :showrunner_contracts do
        collection do
          get 'owned', to: 'showrunner_contracts#owned_contracts'
        end
        member do
          post 'accept'
          post 'complete'
        end
      end

      resources :rarities, only: [:index, :show]
      resources :types, only: [:index, :show]
      resources :games
      resources :user_slots
      resources :user_recharges, only: [:index, :show, :update] do
        collection do
          post 'create'
        end
      end

      resources :badge_useds

      get 'data_lab/slots', to: 'data_lab#slots_metrics'
      get 'data_lab/contracts', to: 'data_lab#contracts_metrics'
      get 'data_lab/badges', to: 'data_lab#badges_metrics'
      get 'data_lab/craft', to: 'data_lab#craft_metrics'

      get 'profile', to: 'users#profile'
      patch 'profile', to: 'users#update_profile'
      delete 'profile', to: 'users#delete_profile'

      # Routes OpenLoot
      get 'open_loot/badges', to: 'open_loot#badges'
      get 'open_loot/showrunner_contracts', to: 'open_loot#showrunner_contracts'
      get 'open_loot/all_listings', to: 'open_loot#all_listings'
      get 'open_loot/currency_stats', to: 'open_loot#currency_stats'
      get 'open_loot/currency_stats/:currency_id', to: 'open_loot#currency_stats'

      # Routes pour daily_metrics
      get 'daily_metrics', to: 'matches#daily_metrics'  # Pour aujourd'hui
      get 'daily_metrics/:date', to: 'matches#daily_metrics'  # Pour une date spécifique

      # Remplacer le namespace summary par des routes directes
      get 'summaries/daily/:date', to: 'summaries#daily'
      get 'summaries/monthly/:date', to: 'summaries#monthly'

      # Routes de paiement
      scope '/payments' do
        # Routes Stripe
        scope '/checkout' do
          post 'create', to: 'checkout#create', as: 'checkout_create'
          get 'success', to: 'checkout#success', as: 'checkout_success'
          get 'cancel', to: 'checkout#cancel', as: 'checkout_cancel'
        end

        # Routes Donation
        scope '/donations' do
          post 'create', to: 'donation#create', as: 'donation_create'
          get 'success', to: 'donation#success', as: 'donation_success'
          get 'cancel', to: 'donation#cancel', as: 'donation_cancel'
        end

        # Webhook Stripe
        post 'webhook', to: 'webhook#webhook', as: 'stripe_webhook'

        # Portail client Stripe
        post 'customer-portal', to: 'customer_portal#create', as: 'customer_portal'
      end

      # Routes d'administration
      namespace :admin do
        resources :users do
          member do
            post 'promote', to: 'users#promote'
            post 'demote', to: 'users#demote'
          end
        end

        # Ajoutez cette ligne pour les devises
        resources :currencies

        # Ajout de la ressource items pour l'administration
        resources :items

        # Autres ressources d'administration
        resources :matches, only: [:index, :show, :destroy]
        resources :nfts, only: [:index, :show, :destroy]

        # Dashboard d'administration
        get 'dashboard', to: 'dashboard#index'

        # Routes pour les devises du jeu
        get 'game_currencies', to: 'game_currencies#index'
        patch 'game_currencies/bft', to: 'game_currencies#update_bft'
        patch 'game_currencies/sponsor_marks', to: 'game_currencies#update_sponsor_marks'
      end

      resources :tournaments do
        resources :teams do
          member do
            post :join
            delete :leave
          end
        end
        
        resources :tournament_matches do
          member do
            patch :update_results
          end
        end
      end
    end
  end
end
