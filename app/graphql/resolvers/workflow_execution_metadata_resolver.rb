# frozen_string_literal: true

module Resolvers
  # Workflow Execution Metadata Resolver
  class WorkflowExecutionMetadataResolver < BaseResolver
    type GraphQL::Types::JSON, null: false

    argument :keys, [GraphQL::Types::String],
             required: false,
             description: 'Optional array of keys to limit metadata result to.',
             default_value: nil

    alias workflow_execution object

    def resolve(args)
      scope = workflow_execution

      return scope.metadata unless args[:keys]

      scope.metadata.slice(*args[:keys])
    end
  end
end
