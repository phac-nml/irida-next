# frozen_string_literal: true

module Types
  # WorkflowExecutions Type
  class WorkflowExecutionType < Types::BaseObject # rubocop:disable convention:GraphQL/ExtractType
    implements GraphQL::Types::Relay::Node
    description 'A workflow execution'

    # TODO: should fields like this have extra types or is an array of strings good enough?
    field :metadata, [String], null: true, description: 'todo'
    field :run_id, String, null: true, description: 'todo'
    field :state, String, null: true, description: 'todo'
    field :submitter, UserType, null: false, description: 'todo'
    field :submitter_id, String, null: true, description: 'todo'
    field :tags, [String], null: true, description: 'todo'

    field :workflow_engine, String, null: true, description: 'todo'
    field :workflow_engine_parameters, [String], null: true, description: 'todo'
    field :workflow_engine_version, String, null: true, description: 'todo'
    field :workflow_params, [String], null: true, description: 'todo'
    field :workflow_type, String, null: true, description: 'todo'
    field :workflow_type_version, String, null: true, description: 'todo'
    field :workflow_url, String, null: true, description: 'todo'

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
