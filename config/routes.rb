# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'dashboard#index'

  # Begin of the /-/ scope.
  # Use this scope for all new global routes.
  scope path: '-' do
    resources :groups, only: %i[index new create destroy]
    draw :profile
  end
  # End of the /-/ scope.

  draw :user
  draw :group
end
