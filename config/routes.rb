# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'dashboard#index'

  # Begin of the /-/ scope.
  # Use this scope for all new global routes.
  scope path: '-' do
    resources :groups, only: %i[index new create]
    resources :projects, only: %i[index new create]
    draw :workflow_executions
    resources :data_exports, only: %i[index new create destroy show] do
      member do
        get :redirect_from
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

  draw :development

  project_routes = Irida::Application.routes.set.filter_map do |route|
    route.name if route.name&.include?('namespace_project')
  end

  project_routes.each do |name|
    short_name = name.sub('namespace_project', 'project')

    direct(short_name) do |project, *args|
      send("#{name}_url", project&.namespace&.parent, project, *args)
    end
  end
end
