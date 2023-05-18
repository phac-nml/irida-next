# frozen_string_literal: true

module Types
  # Base Connection Type
  class BaseConnection < Types::BaseObject
    # add `nodes` and `pageInfo` fields, as well as `edge_type(...)` and `node_nullable(...)` overrides
    include GraphQL::Types::Relay::ConnectionBehaviors

    field :total_count, Integer, null: false, description: 'Identifies the total count of items in the connection.'

    def total_count
      object.items.size
    end
  end
end
