# frozen_string_literal: true

module Resolvers
  # Projects Resolver
  class ProjectsResolver < BaseResolver
    type Types::ProjectType.connection_type, null: true

    argument :group_id, GraphQL::Types::ID,
             required: false,
             description: 'Optional group identifier to return list of projects for (includes direct, indirect, and shared projects).', # rubocop:disable Layout/LineLength
             default_value: nil

    def resolve(group_id:)
      if group_id
        group = IridaSchema.object_from_id(group_id, { expected_type: Group })
        authorize!(group, to: :read?, with: GroupPolicy)
        authorized_scope(Project, type: :relation, as: :group_projects, scope_options: { group: })
      else
        authorized_scope Project, type: :relation
      end
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
    end
  end
end
