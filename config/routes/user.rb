# frozen_string_literal: true

devise_for :users, controllers: {
  # omniauth_callbacks: :omniauth_callbacks,
  registrations: :registrations,
  passwords: :passwords,
  sessions: :sessions
  # confirmations: :confirmations
}

devise_scope :user do
  # get '/auth/saml/callback' => 'users/omniauth_callbacks#saml'
  # get '/auth/developer/callback' => 'users/omniauth_callbacks#developer'

  # Every guide shows these as 'get' requests, not Post, not sure hwy it doesn't work with get
  # It might be cause of the buttons and not the devise shared links??
  post '/auth/:provider/callback' => 'users/omniauth_callbacks#create'
end

constraints(::Constraints::UserUrlConstrainer.new) do
  scope(path: ':username',
        as: :user,
        constraints: { username: Irida::PathRegex.root_namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end
