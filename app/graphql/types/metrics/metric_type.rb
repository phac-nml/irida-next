# frozen_string_literal: true

module Types
  module Metrics
    # Metric Type
    class MetricType < Types::BaseType
      description 'Metrics for a group or user namespace'

      field :projects_count, Integer, null: true,
                                      description: 'Total number of projects under the namespace.',
                                      resolver: Resolvers::Metrics::ProjectsCountResolver

      field :samples_count, Integer, null: false,
                                     description: 'Total number of samples in group projects or user project.',
                                     resolver: Resolvers::Metrics::SamplesCountResolver

      field :disk_usage, String, null: false,
                                 description: 'Disk usage (bytes) of the group projects or user projects.',
                                 resolver: Resolvers::Metrics::DiskUsageResolver

      field :members_count, Integer, null: false,
                                     description: 'Total number of members in the group, subgroups, and/or projects.',
                                     resolver: Resolvers::Metrics::MembersCountResolver
    end
  end
end
