# frozen_string_literal: true

# Module to check if there are workflow executions
module WorkflowExecutions
  def has_workflow_executions?
    @has_workflow_executions = !File.zero?('config/pipelines/pipelines.json')
  end
end
