# frozen_string_literal: true

module Resolvers
  module Metrics
    # Object Resolver for Metrics
    class ObjectResolver < BaseResolver
      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to return only direct records for the object.
                           For example, if true, it will return only direct records for a namespace,
                           but not records for subgroups.',
               default_value: false

      def resolve(direct_only:)
        context.scoped_set!(:direct_only, true) if direct_only
        object
      end
    end
  end
end
