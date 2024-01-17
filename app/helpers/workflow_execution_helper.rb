# frozen_string_literal: true

# Workflow executions view helper
module WorkflowExecutionHelper
  def cancellable?(workflow_execution)
    workflow_execution.state == 'running' ||
      workflow_execution.state == 'queued' ||
      workflow_execution.state == 'prepared'
  end
end
