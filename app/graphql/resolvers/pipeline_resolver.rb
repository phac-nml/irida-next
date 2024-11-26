# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class PipelineResolver < BaseResolver
    argument :workflow_name, String,
             required: true,
             description: 'Name of the Workflow'
    argument :workflow_type, String,
             required: false,
             default_value: 'executable',
             description: "Can specify `automatable` for automatable pipelines, or `available` for all pipelines. By default only 'executable' pipelines are returned." # rubocop:disable Layout/LineLength
    argument :workflow_version, String,
             required: true,
             description: 'Version of the Workflow'

    type Types::PipelineType, null: true

    def resolve(workflow_name:, workflow_version:, workflow_type:)
      Irida::Pipelines.instance.find_pipeline_by(
        workflow_name,
        workflow_version,
        workflow_type
      )
    end
  end
end
