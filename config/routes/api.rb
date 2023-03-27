# frozen_string_literal: true

match '/api/graphql', via: %i[get post], to: 'graphql#execute'

mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/graphql' if Rails.env.development?
