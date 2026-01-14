# frozen_string_literal: true

Rails.application.routes.draw do
  if Rails.env.development?
    default_url_options protocol: ENV.fetch('RAILS_PROTOCOL', 'http'),
                        host: ENV.fetch('RAILS_HOST', 'localhost'),
                        port: ENV.fetch('RAILS_PORT', 3000)
  elsif Rails.env.test? && ENV.key?('DEVCONTAINER')
    default_url_options protocol: ENV.fetch('RAILS_PROTOCOL', 'http'),
                        host: 'rails-app'
  else
    default_url_options protocol: ENV.fetch('RAILS_PROTOCOL', 'http'),
                        host: ENV.fetch('RAILS_HOST', 'localhost')
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'dashboard#index'

  # Begin of the /-/ scope.
  # Use this scope for all new global routes.
  scope path: '-' do
    resources :groups, only: %i[index new create]
    resources :projects, only: %i[index new create]
    resources :samples, only: %i[show edit] do
      resources :metadata, module: :samples, only: %i[update] do
        collection do
          post '/', action: :bulk_create
          patch '/', action: :bulk_update
        end
      end
      scope module: :samples, as: :samples do
        collection do
          resource :transfer, only: %i[create new]
          resource :clone, only: %i[create new]
          resource :deletions, only: %i[new] do
            post :destroy
          end
        end
      end
      collection do
        post :list
      end
    end
    resources :attachments, only: %i[show]
    draw :workflow_executions unless Irida::Pipelines.instance.pipelines.empty?
    resources :data_exports, only: %i[index new create destroy show] do
      member do
        get :redirect
      end
      collection do
        post :list
      end
    end

    draw :profile
  end
  # End of the /-/ scope.

  resources :integration_access_token, only: %i[index create]

  draw :group

  draw :api
  draw :dashboard
  draw :user
  draw :project
  draw :activities

  draw :system
  draw :development
end
