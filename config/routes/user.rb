# frozen_string_literal: true

devise_for :users

constraints(::Constraints::UserUrlConstrainer.new) do # rubocop:disable Style/RedundantConstantBase
  scope(path: ':username',
        as: :user,
        constraints: { username: Irida::PathRegex.root_namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end