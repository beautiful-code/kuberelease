Rails.application.routes.draw do

  resources :suites do
    resources :services
    resources :environments do
      member do
        get 'deployment_details'
        post 'launch_version'
        post 'run_command'
        get :service_commands
        get :service_variables
        get 'show_service/:service_id', action: :show_service, as: :show_service
        get 'service_pod_log/:service_id', action: :service_pod_log
        post :update_variables, action: :update_service_variables
      end
    end
  end

  root 'suites#index'
end
