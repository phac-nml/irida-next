# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
# This will cause the validation to fail if any of the attachment ids cannot be resolved
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator
  def validate(record) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    record.samplesheet_params.each do |key, value|
      next if value == ''

      if key == 'sample'
        unless value == (record.sample.puid)
          record.workflow_execution.errors.add :sample,
                                               'Provided Sample PUID does not match SampleWorkflowExecution Sample PUID'
        end
        next
      end

      begin
        # Attempt to parse an object from the id provided
        attachment = IridaSchema.object_from_id(value, { expected_type: Attachment })
        unless attachment.attachable == record.sample
          record.workflow_execution.errors.add :attachment, 'Attachment does not belong to Sample.'
        end
      rescue StandardError => e
        record.workflow_execution.errors.add :attachment, e.message
        next
      end
    end
  end
end
