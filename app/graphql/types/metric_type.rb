# frozen_string_literal: true

module Types
  # Metric Type
  class MetricType < Types::BaseObject
    description 'Metrics for a project or group'

    field :project_count,
          Integer, null: true,
                   description: "Total number of projects under the group and it's subgroups.",
                   method: :count

    field :samples_count, Integer, null: false, description: 'Total number of samples in the namespace.'

    field :name, String, null: false, description: 'Name of the namespace.'

    field :created_date, GraphQL::Types::ISO8601DateTime, null: false,
                                                          description: 'Creation date of the namespace.',
                                                          method: :created_at

    field :modified_date, GraphQL::Types::ISO8601DateTime, null: false,
                                                           description: 'Last modified date of the namespace.',
                                                           method: :updated_at

    field :disk_usage, Integer, null: false,
                                description: 'Disk usage of the namespace in bytes.',
                                resolver: Resolvers::DiskUsageResolver

    field :members, [[String]], null: false,
                                description: 'Members of the namespace.',
                                resolver: Resolvers::MembersResolver

    field :members_count, Integer, null: false,
                                   description: 'Total number of members in the namespace.'

    def project_count
      return unless object.is_a?(Group)

      object.self_and_descendants_of_type([Project]).count
    end

    def name
      "#{object.name} #{object.puid}"
    end

    def members_count
      if object.project_namespace?
        object.project_members.count
      elsif object.group_namespace?
        object.group_members.count
      end
    end

    def samples_count
      if object.project_namespace?
        object.project.samples_count
      elsif object.group_namespace?
        if context[:include_shared_group_samples] == true
          authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                   scope_options: { namespace: object }).count
        else
          object.samples_count
        end
      end
    end
  end
end
