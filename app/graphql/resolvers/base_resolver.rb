# frozen_string_literal: true

module Resolvers
  # Base Resolver
  class BaseResolver < GraphQL::Schema::Resolver
    include ActionPolicy::GraphQL::Behaviour

    argument_class ::Types::BaseArgument
  end
end
