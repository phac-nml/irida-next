# frozen_string_literal: true

module Resolvers
  module Metrics
    # Object Resolver for Metrics
    class ObjectResolver < BaseResolver
      def resolve
        object
      end
    end
  end
end
