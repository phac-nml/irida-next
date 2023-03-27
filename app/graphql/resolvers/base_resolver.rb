# frozen_string_literal: true

module Resolvers
  # Base Resolver
  class BaseResolver < GraphQL::Schema::Resolver
    argument_class ::Types::BaseArgument
  end
end
