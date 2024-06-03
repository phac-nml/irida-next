# frozen_string_literal: true

module Mutations
  # Base Mutation
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include ActionPolicy::GraphQL::Behaviour

    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    authorize :token, through: :token

    def token
      context[:token]
    end
  end
end
