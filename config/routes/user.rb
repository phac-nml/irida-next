# frozen_string_literal: true

devise_for :users, controllers: {
  # omniauth_callbacks: :omniauth_callbacks,
  registrations: :registrations,
  passwords: :passwords,
  sessions: :sessions
  # confirmations: :confirmations
}

constraints(Constraints::UserUrlConstrainer.new) do
  scope(path: ':username',
        as: :user,
        constraints: { username: Irida::PathRegex.root_namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end
