# frozen_string_literal: true

module Types
  # Module with fields common to all namespace types (groups and projects) for metrics
  module NamespaceMetricType
    include Types::BaseInterface

    comment 'Interface for namespace metrics'
    description 'Something that can be bought'

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
