# frozen_string_literal: true

# Policy for groups authorization
class GraphqlPolicy < ApplicationPolicy
  authorize :token

  def query?
    return true if token&.scopes&.include?(:api) || token&.scopes&.include?(:read_api)

    false
  end

  def mutate?
    return true if token&.scopes&.include?(:api)

    false
  end
end
