# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type WorkflowExecution
  class WorkflowExecutionActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end

    def workflow_execution_exists
      return false if @activity[:workflow_execution].nil?

      if @activity[:automated] == true
        !@activity[:workflow_execution].destroyed?
      else
        !@activity[:workflow_execution].deleted?
      end
    end

    def workflow_execution_sample_exists
      return false if @activity[:sample].nil?

      !@activity[:sample].deleted?
    end
  end
end
