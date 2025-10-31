# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class PipelineResolver < BaseResolver
    argument :pipeline_id, String,
             required: true,
             description: 'ID of the Workflow'
    argument :workflow_type, String,
             required: false,
             default_value: 'executable',
             description: "Can specify `automatable` for automatable pipelines, or `available` for all pipelines. By default only 'executable' pipelines are returned." # rubocop:disable Layout/LineLength
    argument :workflow_version, String,
             required: true,
             description: 'Version of the Workflow'

    type Types::PipelineType, null: true

    def resolve(pipeline_id:, workflow_version:, workflow_type:)
      pipeline = Irida::Pipelines.instance.find_pipeline_by(
        pipeline_id,
        workflow_version
      )

      return nil if pipeline.unknown?

      case workflow_type
      when 'automatable'
        return nil unless pipeline.automatable?
      when 'executable'
        return nil unless pipeline.executable?
      end

      pipeline
    end
  end
end
