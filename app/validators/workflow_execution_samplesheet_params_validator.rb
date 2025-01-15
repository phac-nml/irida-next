# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
# This will cause the validation to fail if any of the attachment ids cannot be resolved
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator
  def validate(record) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    if record.samples_workflow_executions.empty?
      record.errors.add :base, 'Missing samplesheet params'
    else
      record.samples_workflow_executions.each do |sample_workflow_execution|
        sample_workflow_execution.samplesheet_params.each do |key, value|
          next if value == ''

          if key == 'sample'
            unless value == (sample_workflow_execution.sample.puid)
              record.errors.add :sample, 'Provided Sample PUID does not match SampleWorkflowExecution Sample PUID'
            end
            next
          end

          begin
            # Attempt to parse an object from the id provided
            attachment = IridaSchema.object_from_id(value, { expected_type: Attachment })
            unless attachment.attachable == sample_workflow_execution.sample
              record.errors.add :attachment, 'Attachment does not belong to Sample.'
            end
          rescue StandardError => e
            record.errors.add :attachment, e.message
            next
          end
        end
      end
    end
  end
end
