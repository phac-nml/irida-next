# frozen_string_literal: true

module Resolvers
  module Metrics
    # Samples Count Resolver
    class SamplesCountResolver < BaseResolver
      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to only include samples from projects that directly belong to this namespace.',
               default_value: false

      def resolve(direct_only:)
        if object.is_a?(Project)
          object.samples_count.to_i
        elsif object.group_namespace? && !direct_only
          object.aggregated_samples_count.to_i
        else
          Sample.where(project_id: Project.where(namespace_id: object.project_namespaces.pluck(:id))).count
        end
      end
    end
  end
end
