# frozen_string_literal: true

module Validators
  # Base Validator
  class BaseValidator < GraphQL::Schema::Validator
    include ActionPolicy::Behaviour
  end
end
