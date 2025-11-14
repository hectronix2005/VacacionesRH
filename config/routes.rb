Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Ignore Chrome DevTools requests
  get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [204, {}, []] }

  resources :sessions, only: [ :new, :create ] do
    delete :logout, on: :collection, to: "sessions#destroy"
    get :login, on: :collection, to: "sessions#new"
    post :login, on: :collection, to: "sessions#create"
  end

  # Root route - redirect to dashboard
  root "dashboard#index"
  
  # Main dashboard
  get "dashboard" => "dashboard#index", as: :dashboard
  
  # Areas management - HR and Admin only
  resources :areas
  
  # Vacation requests - available to all authenticated users
  resources :vacation_requests do
    member do
      patch :approve
      patch :reject
      patch :mark_as_taken
      get :export_pdf
    end
    
    collection do
      get :pending    # For leaders and HR to see pending requests
      get :history    # User's own history
      get :calendar   # Calendar view of vacations
      get :import     # Import historical data form
      post :import    # Process import of historical data
      get :country_working_days # API endpoint for country working days configuration
      get :export_bulk # Export multiple requests as ZIP
      get :download_import_result # Download temporary import result file
    end
  end
  
  # Vacation balances - HR only
  resources :vacation_balances, except: [:destroy] do
    collection do
      get :by_year
      post :recalculate_all
    end
  end

  # User management - HR only
  resources :users do
    member do
      patch :activate
      patch :deactivate
    end
    collection do
      get :import
      post :import
      get :download_import_result # Download temporary import result file
      get :search # Search users for Tom Select
    end
  end

  # Vacation approval configuration - Admin/HR only
  resources :vacation_approval_configs do
    collection do
      post :setup_defaults
    end
  end
end
