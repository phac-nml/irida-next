# frozen_string_literal: true

# Concern for workflow execution path helpers
module WorkflowExecutionPaths
  extend ActiveSupport::Concern

  def individual_path(workflow_execution)
    if @namespace&.project_namespace?
      namespace_project_workflow_execution_path(
        @namespace.parent,
        @namespace.project,
        workflow_execution
      )
    elsif @namespace&.group_namespace?
      group_workflow_execution_path(@namespace, workflow_execution)
    else
      workflow_execution_path(workflow_execution)
    end
  end

  def cancel_path(workflow_execution)
    if @namespace
      cancel_namespace_project_workflow_execution_path(
        @namespace.parent,
        @namespace.project,
        workflow_execution
      )
    else
      cancel_workflow_execution_path(workflow_execution)
    end
  end

  def destroy_confirmation_path(workflow_execution)
    if @namespace
      destroy_confirmation_namespace_project_workflow_execution_path(@namespace.parent,
                                                                     @namespace.project,
                                                                     workflow_execution)
    else
      destroy_confirmation_workflow_execution_path(workflow_execution)
    end
  end
end
