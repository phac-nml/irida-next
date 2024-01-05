# frozen_string_literal: true

module Resolvers
  # WorkflowExecutions Resolver
  class WorkflowExecutionsResolver < BaseResolver
    type Types::WorkflowExecutionType.connection_type, null: true

    def resolve
      # TODO: should this have a get all for admin users?
      WorkflowExecution.where(submitter: current_user)
    end
  end
end
