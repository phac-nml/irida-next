# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
# This will cause the validation to fail if any of the attachment ids cannot be resolved
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator
  def validate(record)
    if record.samples_workflow_executions.empty?
      record.errors.add :base, 'Missing samplesheet params'
    else
      record.samples_workflow_executions.each do |sample_workflow_execution|
        sample_workflow_execution.samplesheet_params.each do |key, value|
          next if key == 'sample' # We only care about the attachments

          begin
            # Attempt to parse an object from the id provided
            IridaSchema.object_from_id(value, { expected_type: Attachment })
          rescue StandardError => e
            record.errors.add :attachment, e.message
            next
          end
        end
      end
    end
  end
end
