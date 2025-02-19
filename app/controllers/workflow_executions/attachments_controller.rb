# frozen_string_literal: true

module WorkflowExecutions
  # Controller for managing attachments related to workflow executions
  class AttachmentsController < WorkflowExecutionsController
    include BreadcrumbNavigation

    before_action :attachment, only: [:index]
    before_action :workflow_execution, only: [:index]
    before_action :context_crumbs, only: [:index]

    def index
      return if @attachment

      flash.now[:error] = I18n.t('workflow_executions.attachments.errors.not_found')
      render :file_not_found, status: :not_found
      nil
    end

    private

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by!(id: params[:workflow_execution], submitter: current_user)
    rescue ActiveRecord::RecordNotFound
      render file: 'public/404.html', status: :not_found
    end

    def attachment
      @attachment = Attachment.find_by(id: params[:attachment])
    end

    def context_crumbs
      @context_crumbs =
        [{
          name: I18n.t('workflow_executions.index.title'),
          path: workflow_executions_path
        }, {
          name: @workflow_execution.name || @workflow_execution.id,
          path: workflow_execution_path(@workflow_execution,
                                        tab: 'files')
        }]

      @context_crumbs +=
        [{
          name: @attachment.file.filename,
          path: workflow_executions_attachments_path(attachment: @attachment.id,
                                                     workflow_execution: @workflow_execution.id)
        }]
    end
  end
end
