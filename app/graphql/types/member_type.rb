# frozen_string_literal: true

module Types
  # Member Type
  class MemberType < BaseType
    implements GraphQL::Types::Relay::Node
    description 'A member'

    field :access_level, String, null: false, description: 'The access level of the member.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true,
                                                        description: 'The date and time when the membership expires.'

    field :user, UserType, null: false, description: 'The user that is a member of the group.'

    def self.authorized?(object, context)
      super && (context[:member_authorized] ||
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        ))
    end

    def access_level
      I18n.t("members.access_levels.level_#{object.access_level}")
    end
  end
end
