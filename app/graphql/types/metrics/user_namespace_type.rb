# frozen_string_literal: true

module Types
  module Metrics
    # Group Type
    class UserNamespaceType < Types::BaseType
      implements Types::Metrics::NamespaceWithMetricsType

      graphql_name 'UserNamespaceMetricsType'
      description 'User namespace to get metrics for'

      def self.authorized?(object, context)
        super && context[:current_user]&.system?
      end
    end
  end
end
