# frozen_string_literal: true

match '/api/graphql', via: %i[get post], to: 'graphql#execute'

if Rails.env.development? || ENV['GRAPHIQL'].present?
  mount GraphiQL::Rails::Engine, at: '/graphiql',
                                 graphql_path: '/api/graphql'
end
