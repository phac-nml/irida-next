# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an project sample activity
    class WorkflowExecutionActivityComponent < Activities::BaseActivityComponent
      def workflow_execution_destroy_action
        @activity[:action] == 'workflow_execution_destroy'
      end
    end
  end
end
