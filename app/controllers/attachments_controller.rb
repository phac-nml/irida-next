# frozen_string_literal: true

# 🗂️ Controller for managing attachment previews and displays
# Handles how attachments are shown based on their file type
# Supports text, images, FASTA, FASTQ, GenBank, and more!
class AttachmentsController < ApplicationController
  layout 'attachment'

  before_action :check_attachments_preview_enabled
  before_action :set_attachment
  before_action :set_context_crumbs

  # 🖼️ Shows a preview of the attachment if it exists
  # Preview format depends on the file type in metadata
  #
  # 📄 Supported formats:
  # - text (txt, rtf)
  # - image (png, jpg, jpeg, gif, bmp, tiff, svg, webp)
  # - fasta
  # - fastq
  # - genbank
  # - json
  # - csv
  # - tsv
  # - spreadsheet (xls, xlsx)
  def show
    return handle_preview if @attachment.present?

    handle_not_found
  end

  private

  # 🎬 Renders the appropriate preview template based on file format
  def handle_preview
    format = @attachment.metadata['format']
    if lookup_context.template_exists?("attachments/#{format}_preview")
      render "#{format}_preview"
    else
      handle_not_found
    end
  end

  # 🚫 Redirects when attachment can't be found or displayed
  def handle_not_found
    redirect_back fallback_location: request.referer || root_path,
                  alert: I18n.t('attachment.show.file_not_found')
    nil
  end

  # 🔍 Finds and sets the attachment by ID
  # Called automatically before controller actions
  def set_attachment
    @attachment = Attachment.find_by(id: params[:id])
  end

  # ⬇️ Public interface methods ⬇️
  # --------------------------------

  # 🧭 Builds navigation breadcrumbs for current attachment
  # Creates an array of items with names and paths
  #
  # Handles different parent types:
  # - WorkflowExecution
  # - SamplesWorkflowExecution
  def set_context_crumbs
    @context_crumbs = []

    parent = @attachment.attachable

    @context_crumbs.concat(workflow_execution_crumb(parent)) if parent.is_a?(WorkflowExecution)
    @context_crumbs.concat(samples_workflow_execution_crumb(parent)) if parent.is_a?(SamplesWorkflowExecution)
    @context_crumbs << attachment_crumb if @attachment.present?
  end

  # ⬇️ Breadcrumb generation methods ⬇️
  # -----------------------------------

  # 🔗 Creates breadcrumb items for a WorkflowExecution
  # Returns array of hashes with name and path info
  def workflow_execution_crumb(workflow_execution)
    set_workflow_page_context
    [{
      name: I18n.t('workflow_executions.index.title'),
      path: workflow_executions_path
    }, {
      name: workflow_execution.name.presence || workflow_execution.id,
      path: workflow_execution_path(workflow_execution, tab: 'files'),
      workflow_execution: workflow_execution.id
    }]
  end

  # 📝 Sets the current page context for workflow-related views
  def set_workflow_page_context
    @current_page = I18n.t(:'general.default_sidebar.workflows')
  end

  # 🔄 Creates breadcrumbs for SamplesWorkflowExecution
  # Delegates to the associated WorkflowExecution
  def samples_workflow_execution_crumb(samples_workflow_execution)
    workflow_execution_crumb(samples_workflow_execution.workflow_execution)
  end

  # 📎 Creates a breadcrumb for the current attachment
  # Returns hash with filename and path
  def attachment_crumb
    {
      name: @attachment.file.filename.to_s,
      path: attachment_path(attachment: @attachment.id)
    }
  end

  # 🚦 Feature flag check for attachment previews
  # Redirects if the preview feature is disabled
  def check_attachments_preview_enabled
    redirect_back(fallback_location: root_path) unless Flipper.enabled?(:attachments_preview)
  end
end
