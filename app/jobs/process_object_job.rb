# frozen_string_literal: true

# Polling job to process an object and enqueue status job when a certain condition is met.
class ProcessObjectJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 10

  def perform(object_id)
    object = WorkflowExecution.find_by(id: object_id)

    if object.nil?
      # Handle the case where the object no longer exists (e.g., discard job)
      return
    end

    # Check if the condition is met
    time_elapsed = Time.now.to_i - object.created_at.to_i
    min_run_time = object.workflow.settings.fetch('min_run_time', 0).to_i
    if time_elapsed >= min_run_time
      # Condition met: execute the main logic
      process_the_object(object)
    else
      # Condition not met: re-enqueue the job with a delay
      delay = [min_run_time - time_elapsed, 30].max # Ensure at least 30 seconds delay
      re_enqueue_for_later_check(object, delay)
    end
  end

  private

  def process_the_object(object)
    # Your main business logic goes here
    Rails.logger.info "Processing object #{object.id}"
    # ...
    WorkflowExecutionStatusJob.perform_later(object)
  end

  def re_enqueue_for_later_check(object, delay)
    # Use exponential backoff or a fixed delay to avoid overwhelming the system
    # The `wait` option uses ActiveJob's built-in delay functionality
    ProcessObjectJob.set(wait: delay.seconds.from_now).perform_later(object) # Adjust delay as needed
  end
end
