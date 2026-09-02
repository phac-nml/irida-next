# frozen_string_literal: true

module WorkflowExecutions
  module WorkflowSelection
    # Component for rendering selection buttons within launch workflow dialog
    class ButtonComponent < Component
      def initialize(workflow:, disabled_message: '')
        @workflow = workflow
        @disabled_message = disabled_message
        @disabled = @disabled_message.present?
      end
    end
  end
end
