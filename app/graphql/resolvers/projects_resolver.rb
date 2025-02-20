# frozen_string_literal: true

module Resolvers
  # Projects Resolver
  class ProjectsResolver < BaseResolver
    type Types::ProjectType.connection_type, null: true

    argument :group_id, GraphQL::Types::ID,
             required: false,
             description: 'Optional group identifier to return list of projects for (includes direct, indirect, and shared projects).', # rubocop:disable Layout/LineLength
             default_value: nil

    argument :filter, Types::ProjectFilterType,
             required: false,
             description: 'Ransack filter',
             default_value: nil

    argument :order_by, Types::ProjectOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(group_id:, filter:, order_by:)
      context.scoped_set!(:projects_preauthorized, true)
      projects = group_id ? projects_by_group_scope(group_id:) : projects_by_scope
      ransack_obj = projects.ransack(filter&.to_h)
      ransack_obj.sorts = ["#{order_by.field} #{order_by.direction}"] if order_by.present?

      ransack_obj.result
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
      true
    end

    private

    def projects_by_scope
      authorized_scope Project, type: :relation
    end

    def projects_by_group_scope(group_id:)
      group = IridaSchema.object_from_id(group_id, { expected_type: Group })
      authorize!(group, to: :read?, with: GroupPolicy)
      authorized_scope(Project, type: :relation, as: :group_projects, scope_options: { group: })
    end
  end
end
