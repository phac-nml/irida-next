# frozen_string_literal: true

module Resolvers
  # Metrics Resolver
  class MetricsResolver < BaseResolver
    argument :group_full_path, GraphQL::Types::ID,
             required: false,
             description: 'Full path of the group. For example, `pathogen/surveillance`.'
    argument :group_puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifier of the group. For example, `INXT_GRP_AAAAAAAAAA`.'

    argument :project_full_path, GraphQL::Types::ID,
             required: false,
             description: 'Full path of the project. For example, `pathogen/surveillance/2023`.'
    argument :project_puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'

    argument :include_shared_group_samples, Boolean,
             required: false,
             description: 'Include samples from shared groups (only applicable when querying group metrics).',
             default_value: false

    validates required: { one_of: %i[group_full_path group_puid project_full_path project_puid] }

    type Types::MetricType, null: true

    def resolve(**args)
      if args[:project_full_path] || args[:project_puid]
        if args[:project_full_path]
          Namespaces::ProjectNamespace.find_by_full_path(args[:project_full_path]) # rubocop:disable Rails/DynamicFindBy
        else
          Namespaces::ProjectNamespace.find_by(puid: args[:project_puid])
        end
      else
        context.scoped_set!(:include_shared_group_samples, args[:include_shared_group_samples])
        if args[:group_full_path]
          Group.find_by_full_path(args[:group_full_path]) # rubocop:disable Rails/DynamicFindBy
        else
          Group.find_by(puid: args[:group_puid])
        end
      end
    end

    def ready?(**_args)
      authorize!(to: :metrics?, with: GraphqlPolicy, context: { token: context[:token] })
      true
    end
  end
end
