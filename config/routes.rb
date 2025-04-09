# frozen_string_literal: true

Rails.application.routes.draw do
  if ENV.fetch('RAILS_ENV', 'development') == 'development'
    default_url_options protocol: ENV.fetch('RAILS_PROTOCOL', 'http'),
                        host: ENV.fetch('RAILS_HOST', 'localhost'),
                        port: ENV.fetch('RAILS_PORT', 3000)
  else
    default_url_options protocol: ENV.fetch('RAILS_PROTOCOL', 'http'),
                        host: ENV.fetch('RAILS_HOST', 'localhost')
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

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
    end
    resources :attachments, only: %i[show]
    draw :workflow_executions unless Irida::Pipelines.instance.available_pipelines.empty?
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

  draw :group

  draw :api
  draw :dashboard
  draw :user
  draw :project
  draw :activities

  draw :development
end
