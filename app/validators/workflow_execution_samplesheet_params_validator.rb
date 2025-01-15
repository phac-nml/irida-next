# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
# This will cause the validation to fail if any of the attachment ids cannot be resolved
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator
  def validate(record) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    record.samplesheet_params.each do |key, value| # rubocop:disable Metrics/BlockLength
      if key == 'sample'
        if value.nil? || value == ''
          error_message = 'No Sample PUID provided'
          record.errors.add :sample, error_message
          record.workflow_execution.errors.add :sample, error_message
        elsif value != (record.sample.puid)
          error_message = "Provided Sample PUID #{value} does not match SampleWorkflowExecution Sample PUID #{record.sample.puid}" # rubocop:disable Layout/LineLength
          record.errors.add :sample, error_message
          record.workflow_execution.errors.add :sample, error_message
        end
        next
      end

      next if value == ''

      begin
        # Attempt to parse an object from the id provided
        attachment = IridaSchema.object_from_id(value, { expected_type: Attachment })
        unless attachment.attachable == record.sample
          error_message = "Attachment does not belong to Sample #{record.sample.puid}."
          record.errors.add :attachment, error_message
          record.workflow_execution.errors.add :attachment, error_message
        end
      rescue StandardError => e
        error_message = e.message
        record.errors.add :attachment, error_message
        record.workflow_execution.errors.add :attachment, error_message
        next
      end
    end
  end
end
