# frozen_string_literal: true

module Types
  # Metric Type
  class MetricType < Types::BaseType
    description 'Metrics for a group or project'

    field :project_count, Integer, null: true,
                                   description: "Total number of projects under the group and it's subgroups."

    field :samples_count, Integer, null: false, description: 'Total number of samples in group projects or project.',
                                   resolver: Resolvers::SamplesCountResolver

    field :disk_usage, String, null: false,
                               description: 'Disk usage (bytes) of the group projects or project.',
                               resolver: Resolvers::DiskUsageResolver

    field :members_count, Integer, null: false,
                                   description: 'Total number of members in the group or project.'

    def project_count
      return unless object.is_a?(Group)

      object.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
    end

    def members_count # rubocop:disable GraphQL/ResolverMethodLength,Metrics/AbcSize,Metrics/MethodLength
      if object.is_a?(Project)
        if object.namespace.parent.group_namespace?
          Member.joins(:user).where(
            user: { user_type: User.user_types[:human] },
            namespace_id: [object.namespace.id] + object.namespace.parent.self_and_ancestors_of_type([Group.sti_name])
                                                  .select(:id)
          ).select(:user_id).distinct.count

        else
          object.namespace.project_members.joins(:user).where(
            user: { user_type: User.user_types[:human] }
          ).count + 1 # +1 for owner
        end
      elsif object.group_namespace?
        Member.joins(:user).where(
          user: { user_type: User.user_types[:human] },
          namespace_id: object.self_and_ancestors_of_type([Group.sti_name]).select(:id)
        ).select(:user_id).distinct.count
      end
    end
  end
end
