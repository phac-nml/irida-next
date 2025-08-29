# frozen_string_literal: true

# Policy for graphql authorization
class GraphqlPolicy < ApplicationPolicy
  # nil is allowed as a user accessing the api through graphiql while logged into the website would not have a token
  authorize :token, allow_nil: true

  def query?
    return true if token_allows_read?
    return true if token.nil? && !user.nil? # allow users with a session to query the api

    false
  end

  private

  def token_allows_read?
    return false unless token&.active?

    scopes = token.scopes
    scopes&.to_set&.intersect?(%w[api read_api].to_set)
  end

  def mutate? # rubocop:disable Metrics/CyclomaticComplexity
    return true if token&.active? && token&.scopes&.include?('api')
    return true if token.nil? && !user.nil? # allow users with a session to mutate the api

    false
  end
end
