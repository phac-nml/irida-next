# frozen_string_literal: true

if Rails.env.development?
  get '/rails/mailers'         => 'rails/mailers#index'
  get '/rails/mailers/:path'   => 'rails/mailers#preview'
  get '/rails/info/properties' => 'rails/info#properties'
  get '/rails/info/routes'     => 'rails/info#routes'
  get '/rails/info'            => 'rails/info#index'

  mount Lookbook::Engine, at: '/rails/lookbook'
end
