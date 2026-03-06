# frozen_string_literal: true

module Resolvers
  # Members Resolver
  class MembersResolver < BaseResolver
    type Types::MemberType.connection_type, null: true

    argument :user_type, [String],
             required: false,
             description: 'Type of the user (e.g., bot, human, etc.)',
             default_value: nil

    def resolve(user_type:) # rubocop:disable Metrics/AbcSize
      return if object.is_a?(Namespaces::UserNamespace)

      context.scoped_set!(:member_authorized, true)

      members = if object.is_a?(Project)
                  if object.namespace.parent.is_a?(Group)
                    Member.where(namespace: object.namespace.parent.self_and_ancestors) +
                      object.namespace.project_members
                  end
                else
                  Member.where(namespace: object.self_and_ancestors)
                end

      if user_type.present?
        members.joins(:user).where(users: { user_type: user_type })
      else
        members
      end
    end
  end
end
