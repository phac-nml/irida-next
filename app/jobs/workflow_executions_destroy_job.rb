# frozen_string_literal: true

# delete/destroy WorkflowExecutions that have been deleted X days ago
class WorkflowExecutionsDestroyJob < ApplicationJob
  queue_as :default
  queue_with_priority 50

  # Finds all deleted workflow executions more than `days_old`` days old, and destroys them
  # Params:
  # +days_old+:: positive integer. Number of days old and older to destroy. Default is 1
  def perform(days_old: 1)
    if !days_old.instance_of?(Integer) || (days_old < 1)
      err = "'#{days_old}' is not a positive integer!"
      Rails.logger.error err
      raise err
    end

    Rails.logger.info "Cleaning up all deleted workflow executions which are at least #{days_old} days old."

    workflow_executions_to_delete = WorkflowExecution.only_deleted.where(deleted_at: ..(Date.yesterday.midnight - days_old.day)) # rubocop:disable Layout/LineLength
    workflow_executions_to_delete.find_in_batches(batch_size: 50) do |group|
      group.each(&:really_destroy!)
    end
  end
end
