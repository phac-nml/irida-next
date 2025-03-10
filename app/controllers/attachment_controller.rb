# frozen_string_literal: true

# Controller for managing individual attachment previews and displays.
# This controller handles the presentation of attachments based on their format
# and supports various file types including text, images, and specialized formats
# like FASTA, FASTQ, and GenBank files.
#
# The controller uses the Attachable concern for handling breadcrumb navigation
# and context management for attachments in the application.
#
# @see Attachable
# @see Attachment
class AttachmentController < ApplicationController
  layout 'attachment'

  before_action :ensure_enabled
  before_action :attachment
  before_action :context_crumbs
  before_action :current_page

  # Displays a preview of the attachment if the file exists and preview is enabled.
  # The preview format is determined by the attachment's metadata format.
  #
  # Supported preview formats:
  # - text (txt, rtf)
  # - image (png, jpg, jpeg, gif, bmp, tiff, svg, webp)
  # - fasta
  # - fastq
  # - genbank
  # - json
  # - csv
  # - tsv
  # - spreadsheet (xls, xlsx)
  #
  # @return [void]
  # @raise [ActionController::UnknownFormat] if the format is not supported
  def show
    @attachments_preview_enabled ||= Flipper.enabled?(:attachments_preview)
    return handle_preview if @attachment.present? && @attachments_preview_enabled

    handle_not_found
  end

  private

  # Handles the preview rendering based on the attachment format
  #
  # @return [void]
  def handle_preview
    format = @attachment.metadata['format']
    render "#{format}_preview"
  end

  # Handles the case when the attachment is not found or preview is not available
  #
  # @return [void]
  def handle_not_found
    redirect_back fallback_location: request.referer || root_path,
                  alert: I18n.t('attachment.show.file_not_found')
    nil
  end

  # Finds and sets the attachment based on the id parameter.
  # This method is automatically called before any controller action via before_action.
  #
  # @return [Attachment, nil] The found attachment or nil if not found
  # @example
  #   attachment
  #   # => #<Attachment id: 123, ...>
  def attachment
    @attachment = Attachment.find_by(id: params[:id])
  end

  # Public interface methods
  # ----------------------

  # Builds the breadcrumb navigation trail for the current attachment context.
  # This method populates @context_crumbs with an array of breadcrumb items,
  # each containing a name and path for navigation.
  #
  # The breadcrumb trail is constructed based on the attachment's parent object
  # (attachable) and the attachment itself. It supports different types of
  # attachable objects, including WorkflowExecution and SamplesWorkflowExecution.
  #
  # @return [void]
  # @raise [RuntimeError] If attachment has not been set via #attachment method
  def context_crumbs
    @context_crumbs = []

    parent = @attachment.attachable

    @context_crumbs.concat(workflow_execution_crumb(parent)) if parent.is_a?(WorkflowExecution)
    @context_crumbs.concat(samples_workflow_execution_crumb(parent)) if parent.is_a?(SamplesWorkflowExecution)
    @context_crumbs << attachment_crumb if @attachment.present?
  end

  # Sets the current sidebar tab based on the presence of workflow execution parameters.
  #
  # @return [void]
  def current_page
    @current_page = I18n.t(:'general.default_sidebar.workflows') if params[:workflow_execution].present?
  end

  # Breadcrumb generation methods
  # ---------------------------

  # Generates breadcrumb items for a WorkflowExecution object.
  #
  # @param workflow_execution [WorkflowExecution] The workflow execution object
  # @return [Array<Hash>] Array of breadcrumb items with name and path information
  # @example
  #   workflow_execution_crumb(workflow_execution)
  #   # => [
  #   #      { name: "Workflow Executions", path: "/workflow_executions" },
  #   #      { name: "Workflow #123", path: "/workflow_executions/123?tab=files" }
  #   #    ]
  def workflow_execution_crumb(workflow_execution)
    [{
      name: I18n.t('workflow_executions.index.title'),
      path: workflow_executions_path
    }, {
      name: workflow_execution.name.presence || workflow_execution.id,
      path: workflow_execution_path(workflow_execution, tab: 'files'),
      workflow_execution: workflow_execution.id
    }]
  end

  # Generates breadcrumb items for a SamplesWorkflowExecution object by
  # delegating to the associated WorkflowExecution.
  #
  # @param samples_workflow_execution [SamplesWorkflowExecution] The samples workflow execution object
  # @return [Array<Hash>] Array of breadcrumb items with name and path information
  def samples_workflow_execution_crumb(samples_workflow_execution)
    workflow_execution_crumb(samples_workflow_execution.workflow_execution)
  end

  # Creates a breadcrumb item for the current attachment.
  #
  # @return [Hash] A breadcrumb item containing the attachment's filename and path
  # @example
  #   attachment_crumb
  #   # => { name: "example.pdf", path: "/workflow_executions/attachments/123" }
  def attachment_crumb
    {
      name: @attachment.file.filename,
      path: workflow_executions_attachments_path(attachment: @attachment.id)
    }
  end

  # Ensures that the attachments preview feature is enabled.
  def ensure_enabled
    redirect_back(fallback_location: root_path) unless Flipper.enabled?(:attachments_preview)
  end
end
