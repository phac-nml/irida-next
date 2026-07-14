# frozen_string_literal: true

module DataExports
  # Calculates source-file totals for export limit checks without downloading files.
  class ExportSourceSizeCalculator
    def initialize(export_type:, export_parameters:)
      @export_type = export_type
      @export_parameters = export_parameters || {}
    end

    def execute
      case @export_type
      when 'sample'
        sample_export_source_size
      when 'analysis'
        analysis_export_source_size
      else
        0
      end
    end

    private

    def sample_export_source_size
      sample_attachment_scope.sum('active_storage_blobs.byte_size')
    end

    def analysis_export_source_size
      workflow_execution_output_scope.sum('active_storage_blobs.byte_size') +
        sample_workflow_execution_output_scope.sum('active_storage_blobs.byte_size')
    end

    def sample_attachment_scope
      scope = attachments_scope.where(
        attachable_type: 'Sample',
        attachable_id: selected_ids
      )

      return scope if selected_attachment_formats.blank?

      scope.where("attachments.metadata ->> 'format' IN (?)", selected_attachment_formats)
    end

    def workflow_execution_output_scope
      attachments_scope.where(
        attachable_type: 'WorkflowExecution',
        attachable_id: selected_ids
      )
    end

    def sample_workflow_execution_output_scope
      attachments_scope.where(
        attachable_type: 'SamplesWorkflowExecution',
        attachable_id: SamplesWorkflowExecution.where(workflow_execution_id: selected_ids).select(:id)
      )
    end

    def attachments_scope
      Attachment.joins(:file_blob)
    end

    def selected_ids
      Array(@export_parameters['ids'])
    end

    def selected_attachment_formats
      Array(@export_parameters['attachment_formats'])
    end
  end
end
