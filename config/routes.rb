# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'dashboard#index'

  # Begin of the /-/ scope.
  # Use this scope for all new global routes.
  scope path: '-' do
    resources :groups, only: %i[index new create]
    resources :projects, only: %i[new create]

    resources :members, only: %i[index new create destroy]
    draw :profile
  end
  # End of the /-/ scope.

  draw :group

  draw :user
  draw :project

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
