# frozen_string_literal: true

module Types
  # User Type
  class UserType < Types::BaseType
    description 'A user'

    field :email, String, null: false, description: 'User email.'
    field :id, ID, null: false, description: 'ID of the user.'
  end
end
