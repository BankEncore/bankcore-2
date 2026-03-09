Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "transactions#index"

  resources :transactions, only: %i[index show new create] do
    member do
      get :reverse_preview
      post :reverse
    end
  end
  resources :account_lookups, only: %i[index], path: "account-lookups", defaults: { format: :json }

  resources :accounts, only: %i[index show new create] do
    resources :account_holds, only: %i[new create], shallow: true
    resources :account_owners, only: %i[new create], shallow: true
  end
  resources :account_products, only: %i[index show new create edit update] do
    resources :fee_rules, only: %i[new create]
    resources :interest_rules, only: %i[new create]
  end
  resources :fee_rules, only: %i[edit update]
  resources :interest_rules, only: %i[edit update]
  post "account_holds/:id/release", to: "account_holds#release", as: :release_account_hold

  resources :business_dates, only: %i[index show] do
    member { post :close }
  end

  resources :parties, only: %i[index show new create edit update]

  resources :fee_types, only: %i[index new create edit update], path: "fee-types"
  resources :fee_assessments, only: %i[index], path: "fee-assessments"
  resources :interest_accruals, only: %i[index], path: "interest-accruals" do
    collection { post :run }
  end
  resources :interest_postings, only: %i[index create], path: "interest-postings"
  resources :audit_events, only: %i[index], path: "audit-events"
  resources :branches, only: %i[index show]
  resources :gl_accounts, only: %i[index], path: "gl-accounts"
  resources :trial_balances, only: %i[index show], path: "trial-balance"

  resources :override_requests, only: %i[index show new create] do
    member do
      post :approve
      post :deny
    end
  end

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
end
