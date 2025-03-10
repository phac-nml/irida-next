# frozen_string_literal: true

# The Attachable concern provides functionality for handling breadcrumb navigation
# and context management for attachments in the application. It is primarily used
# in controllers that deal with attachments, particularly in the context of
# workflow executions and their associated files.
#
# This concern helps maintain consistent navigation context when viewing or
# managing attachments, ensuring users can easily navigate back through the
# hierarchy of workflow executions and their associated files.
#
# Required setup:
# - The including controller must have an id parameter available
# - The attachment must have an attachable association
# - The attachable must be either a WorkflowExecution or SamplesWorkflowExecution
#
# @example
#   class WorkflowExecutionsController < ApplicationController
#     include Attachable
#
#     def show
#       context_crumbs
#       # ... rest of controller code
#     end
#   end
module Attachable
  extend ActiveSupport::Concern

  included do
    before_action :attachment
    before_action :context_crumbs
    before_action :current_page
  end

  private

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
end
