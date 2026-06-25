# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Update a WorkflowExecution
  class UpdateService < BaseService
    class UpdateError < StandardError
    end

    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
    end

    def execute
      validate_project_not_archived if @workflow_execution.namespace.project_namespace?

      authorize! @workflow_execution, to: :update?
      @workflow_execution.update(params)

      @workflow_execution
    rescue WorkflowExecutions::UpdateService::UpdateError => e
      @workflow_execution.namespace.errors.add(:base, e.message)
      @workflow_execution
    end

    private

    def validate_project_not_archived
      return if @workflow_execution.namespace.archived_at.blank?

      raise UpdateError,
            I18n.t('services.workflow_executions.update.project_read_only')
    end
  end
end
