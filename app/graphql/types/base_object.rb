# frozen_string_literal: true

module Types
  # BaseObject
  class BaseObject < GraphQL::Schema::Object
    include ActionPolicy::GraphQL::Behaviour

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    # All graphql fields exposing an id, should expose a global id.
    def id
      IridaSchema.id_from_object(object)
    end
  end
end
