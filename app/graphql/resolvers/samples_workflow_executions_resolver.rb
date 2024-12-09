# frozen_string_literal: true

module Resolvers
  # Samples WorkflowExecutions Resolver
  class SamplesWorkflowExecutionsResolver < BaseResolver
    type Types::SamplesWorkflowExecutionType, null: true

    alias workflow_execution object

    def resolve
      scope = workflow_execution
      scope.samples_workflow_executions
    end
  end
end
