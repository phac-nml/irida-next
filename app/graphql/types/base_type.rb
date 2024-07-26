# frozen_string_literal: true

module Types
  # Base Type
  class BaseType < Types::BaseObject
    # ISO8601DateTime field
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Datetime of creation.'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Datetime of last update.'
  end
end
