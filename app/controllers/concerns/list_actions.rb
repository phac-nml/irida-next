# frozen_string_literal: true

# List actions to display samples or workflow executions
module ListActions
  extend ActiveSupport::Concern

  def list # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @page = params[:page].to_i
    case params[:list_class]
    when 'sample'
      @samples = Sample.where(id: params[:sample_ids])
    when 'workflow_execution'
      @workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
    when 'attachment'
      # handles flattening attachment_ids where PE files come in as a nested array and need further parsing
      # PE files are outputted as individual ids
      flattened_attachment_ids = params[:attachment_ids].flat_map do |item|
        parsed = JSON.parse(item)
        parsed.is_a?(Array) ? parsed : item
      rescue JSON::ParserError
        item
      end

      @attachments = Attachment.where(id: flattened_attachment_ids)
    end

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end
end
