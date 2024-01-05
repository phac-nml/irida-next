# frozen_string_literal: true

module Types
  # WorkflowExecutions Type
  class WorkflowExecutionType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A workflow execution'

    field :description, String, null: true, description: 'Description of the workflow execution.'
    # field :metadata, String, nul: true, description: 'todo'
    # field :workflow_params
    field :workflow_type, String, null: true, description: 'todo'
    field :submitter, UserType, null: false, description: 'todo'

    field :samples,
          SampleType.connection_type,
          null: true,
          description: 'Samples on the workflow execution',
          complexity: 5,
          resolver: Resolvers::SamplesWorkflowExecutionsResolver

    def self.authorized?(object, context)
      super # TODO: add additional authorization?
      # super &&
      #   allowed_to?(
      #     :read?,
      #     object,
      #     context: { user: context[:current_user] }
      #   )
    end
  end
end
