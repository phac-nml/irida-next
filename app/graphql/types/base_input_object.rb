# frozen_string_literal: true

module Types
  # Base Input Object
  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class Types::BaseArgument
  end
end
