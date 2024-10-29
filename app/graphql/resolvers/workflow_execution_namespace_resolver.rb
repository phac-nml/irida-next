# frozen_string_literal: true

module Resolvers
  # Workflow Execution Namespace Resolver
  class WorkflowExecutionNamespaceResolver < BaseResolver
    type Types::NamespaceType, null: true

    alias workflow_execution object

    def resolve
      scope = workflow_execution

      scope.namespace
    end
  end
end
