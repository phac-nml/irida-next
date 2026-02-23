# frozen_string_literal: true

module Types
  module Metrics
    # Metric Type
    class MetricType < Types::BaseType
      description 'Metrics for a group or project'

      field :project_count, Integer, null: true,
                                     description: "Total number of projects under the group and it's subgroups."

      field :samples_count, Integer, null: false, description: 'Total number of samples in group projects or project.',
                                     resolver: Resolvers::Metrics::SamplesCountResolver

      field :disk_usage, String, null: false,
                                 description: 'Disk usage (bytes) of the group projects or project.',
                                 resolver: Resolvers::Metrics::DiskUsageResolver

      field :members_count, Integer, null: false,
                                     description: 'Total number of members in the group or project.',
                                     resolver: Resolvers::Metrics::MembersCountResolver

      def project_count
        return if object == Project.sti_name

        if object.group_namespace?
          object.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
        elsif object.user_namespace?
          object.project_namespaces.count
        end
      end
    end
  end
end
