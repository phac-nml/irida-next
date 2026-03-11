# frozen_string_literal: true

module Resolvers
  module Metrics
    # Members Resolver
    class MembersResolver < BaseResolver
      type Types::Metrics::MemberType.connection_type, null: true

      argument :user_type, [String],
               required: false,
               description: 'Type of the user (e.g., human, group_bot,project_bot, project_automation_bot)',
               default_value: ['human']

      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'By default this will return direct and inherited members.
               Setting this to `true` will return only direct members.',
               default_value: false

      def resolve(user_type:, direct_only:)
        return if object.is_a?(Namespaces::UserNamespace)

        return if user_type.blank?

        members = namespace_members(direct_only)

        members.joins(:user).where(users: { user_type: user_type })
      end

      private

      def namespace_members(direct_only)
        if direct_only
          return object.namespace.project_members if object.is_a?(Project)

          object.group_members
        else
          namespace = if object.is_a?(Group)
                        object
                      else
                        object.namespace
                      end

          authorized_scope(Member, type: :relation,
                                   scope_options: { namespace: namespace })
        end
      end
    end
  end
end
