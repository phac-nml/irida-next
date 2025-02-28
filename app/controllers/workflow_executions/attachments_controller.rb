# frozen_string_literal: true

module WorkflowExecutions
  # Controller for managing attachments related to workflow executions
  class AttachmentsController < WorkflowExecutionsController
    include BreadcrumbNavigation
    helper ExcelHelper

    before_action :workflow_execution, only: [:index]
    before_action :attachment, only: [:index]
    before_action :context_crumbs, only: [:index]

    def index
      return if @attachment

      redirect_back fallback_location: workflow_executions_path,
                    alert: I18n.t('workflow_executions.attachments.file_not_found')
      nil
    end

    private

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by!(id: params[:workflow_execution], submitter: current_user)
    end

    def attachment
      @attachment = Attachment.find_by(id: params[:attachment])
    end

    def context_crumbs
      @context_crumbs = [base_crumb].then do |crumbs|
        @workflow_execution ? crumbs.concat(workflow_execution_crumbs) : crumbs
      end
    end

    def base_crumb
      {
        name: I18n.t('workflow_executions.index.title'),
        path: workflow_executions_path
      }
    end

    def workflow_execution_crumbs
      return [] unless @attachment.present? && @workflow_execution.present?

      [
        {
          name: @workflow_execution.name || @workflow_execution.id,
          path: workflow_execution_path(@workflow_execution, tab: 'files')
        },
        {
          name: @attachment.file.filename,
          path: workflow_executions_attachments_path(
            attachment: @attachment.id,
            workflow_execution: @workflow_execution.id
          )
        }
      ]
    end
  end
end
