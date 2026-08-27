# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.event.subscribe(AutomatedWorkflowExecutionSubscriber.new)
end
