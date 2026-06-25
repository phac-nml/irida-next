# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Create a new AutomatedWorkflowExecution
  class CreateService < BaseService
    class AutomatedWorkflowExecutionsCreateError < StandardError
    end

    def initialize(user = nil, params = {})
      super
    end

    def execute # rubocop:disable Metrics/MethodLength
      @automated_workflow_execution = AutomatedWorkflowExecution.new(params.merge(created_by: current_user))
      namespace = @automated_workflow_execution.namespace

      validate_project_not_archived

      authorize! namespace, to: :create_automated_workflow_executions? if namespace.present?

      @automated_workflow_execution.save

      if @automated_workflow_execution.persisted?
        namespace.create_activity key: 'workflow_execution.automated_workflow.create',
                                  owner: current_user,
                                  parameters: {
                                    workflow_id: @automated_workflow_execution.id,
                                    automated: true
                                  }
      end

      @automated_workflow_execution
    rescue AutomatedWorkflowExecutions::CreateService::AutomatedWorkflowExecutionsCreateError => e
      @automated_workflow_execution.errors.add(:base, e.message)
      @automated_workflow_execution
    end

    private

    def validate_project_not_archived
      return unless @automated_workflow_execution.namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    @automated_workflow_execution.namespace.archived_at.present?

      raise AutomatedWorkflowExecutionsCreateError,
            I18n.t('services.automated_workflow_executions.create.project_read_only')
    end
  end
end
