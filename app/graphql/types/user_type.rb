# frozen_string_literal: true

module Types
  # User Type
  class UserType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A user'

    field :email, String, null: false, description: 'User email.'
    field :id, ID, null: false, description: 'ID of the user.'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
