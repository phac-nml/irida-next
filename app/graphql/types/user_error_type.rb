# frozen_string_literal: true

module Types
  # User Type
  class UserErrorType < Types::BaseObject
    description 'A user-readable error'

    field :message, String, null: false, description: 'A description of the error'
    field :path, [String], description: 'Which input value this error came from'
  end
end
