# frozen_string_literal: true

module Types
  # Metric Type
  class MetricType < Types::BaseType
    description 'Metrics for a group or project'

    field :project_count,
          Integer, null: true,
                   description: "Total number of projects under the group and it's subgroups.",
                   method: :count

    field :samples_count, Integer, null: false, description: 'Total number of samples in group projects or project.'

    field :name, String, null: false, description: 'Name of the  group or project.'

    field :disk_usage, Integer, null: false,
                                description: 'Disk usage of the group projects or project in bytes.',
                                resolver: Resolvers::DiskUsageResolver

    field :members, [[String]], null: false,
                                description: 'Members of the group or project.',
                                resolver: Resolvers::MembersResolver

    field :members_count, Integer, null: false,
                                   description: 'Total number of members in the group or project.'

    def project_count
      return unless object.is_a?(Group)

      object.self_and_descendants_of_type([Project]).count
    end

    def name
      "#{object.name} (#{object.puid})"
    end

    def members_count
      if object.is_a?(Project)
        object.namespace.project_members.count
      elsif object.group_namespace?
        object.group_members.count
      end
    end

    def samples_count
      if object.is_a?(Project)
        object.samples_count
      elsif object.group_namespace?
        authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                 scope_options: { namespace: object }).count
      end
    end
  end
end
