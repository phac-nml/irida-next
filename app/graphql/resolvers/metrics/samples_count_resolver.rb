# frozen_string_literal: true

module Resolvers
  module Metrics
    # Samples Count Resolver
    class SamplesCountResolver < BaseResolver
      def resolve
        if object.is_a?(Project)
          object.samples_count.to_i
        elsif object.group_namespace?
          object.aggregated_samples_count.to_i
        else
          Sample.where(project_id: Project.where(namespace_id: object.project_namespaces.pluck(:id))).count
        end
      end
    end
  end
end
