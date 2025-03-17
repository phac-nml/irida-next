# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an project sample activity
    class WorkflowExecutionActivityComponent < BaseActivityComponent
      def workflow_execution_destroy_multiple_action
        @activity[:action] == 'workflow_execution_destroy_multiple'
      end

      def workflow_execution_destroy_action
        @activity[:action] == 'workflow_execution_destroy'
      end
    end
  end
end
