# frozen_string_literal: true

module WorkflowExecutions
  def has_workflow_executions?
    @has_workflow_executions = !File.zero?('config/pipelines/pipelines.json')
  end
end
