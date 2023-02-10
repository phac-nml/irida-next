# frozen_string_literal: true

Rails.application.routes.draw do
  get 'hello_world', to: 'hello_world#index'
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'dashboard#index'
end
