# frozen_string_literal: true

# Queues the workflow execution preparation job
class WorkflowExecutionNewJob < ApplicationJob
  queue_as :default

  def perform
    WorkflowExecutionPreparationJob.set(wait_until: 30.seconds.from_now).perform_later
  end
end
