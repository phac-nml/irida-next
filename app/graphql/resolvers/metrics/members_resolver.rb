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

      argument :source, GraphQL::Types::String,
               required: false,
               description: 'The source of the members (e.g., inherited, or direct).',
               default_value: 'inherited'

      def resolve(user_type:, source:)
        return if object.is_a?(Namespaces::UserNamespace)

        return if user_type.blank?

        members = namespace_members(source)

        members.joins(:user).where(users: { user_type: user_type })
      end

      private

      def namespace_members(source)
        if source == 'inherited'
          namespace = if object.is_a?(Group)
                        object
                      else
                        object.namespace
                      end

          authorized_scope(Member, type: :relation,
                                   scope_options: { namespace: namespace })
        else
          return object.namespace.project_members if object.is_a?(Project)

          object.group_members
        end
      end
    end
  end
end
