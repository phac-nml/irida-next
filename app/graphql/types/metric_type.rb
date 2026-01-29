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

    field :disk_usage, String, null: false,
                               description: 'Disk usage of the group projects or project.',
                               resolver: Resolvers::DiskUsageResolver

    field :members_count, Integer, null: false,
                                   description: 'Total number of members in the group or project.'

    def project_count
      return unless object.is_a?(Group)

      object.self_and_descendants_of_type([Project]).count
    end

    def members_count # rubocop:disable GraphQL/ResolverMethodLength,Metrics/AbcSize
      if object.is_a?(Project)
        if object.namespace.parent.group_namespace?
          Member.where(
            namespace_id: [object.namespace.id, object.namespace.self_and_ancestors_of_type([Group]).select(:id)]
          ).count
        else
          object.namespace.project_members.count
        end
      elsif object.group_namespace?
        Member.where(namespace_id: object.self_and_ancestors_of_type([Group]).select(:id)).count
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
