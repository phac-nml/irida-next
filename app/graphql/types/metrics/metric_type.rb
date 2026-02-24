# frozen_string_literal: true

module Types
  module Metrics
    # Metric Type
    class MetricType < Types::BaseType
      description 'Metrics for a group or user namespace'

      field :projects_count, Integer, null: true,
                                      description: 'Total number of projects under the namespace.'

      field :samples_count, Integer, null: false,
                                     description: 'Total number of samples in group projects or user project.',
                                     resolver: Resolvers::Metrics::SamplesCountResolver

      field :disk_usage, String, null: false,
                                 description: 'Disk usage (bytes) of the group projects or user projects.',
                                 resolver: Resolvers::Metrics::DiskUsageResolver

      field :members_count, Integer, null: false,
                                     description: 'Total number of members in the group, subgroups, and/or projects.',
                                     resolver: Resolvers::Metrics::MembersCountResolver

      def projects_count
        return if object.is_a?(Project)

        if object.group_namespace?
          object.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
        elsif object.user_namespace?
          object.project_namespaces.count
        end
      end
    end
  end
end
