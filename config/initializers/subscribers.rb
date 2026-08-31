# frozen_string_literal: true

# Centralized subscriber registration for events.
Rails.application.config.after_initialize do
  Rails.event.subscribe(AutomatedWorkflowExecutionSubscriber.new)
end
