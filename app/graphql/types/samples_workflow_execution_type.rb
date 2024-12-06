# frozen_string_literal: true

module Types
  # SamplesWorkflowExecition Type
  class SamplesWorkflowExecutionType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A SamplesWorkflowExecition'

    field :sample, Types::SampleType, null: true, description: 'Sample'
    field :workflow_execution, Types::WorkflowExecutionType, null: true, description: 'WorkflowExecution'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object.workflow_execution,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
