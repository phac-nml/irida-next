# frozen_string_literal: true

# Permanently deletes samples that have been soft deleted 'x' days ago.
class SamplesCleanupJob < ApplicationJob
  queue_as :default
  queue_with_priority 50

  def perform(days_old: 7)
    if !days_old.instance_of?(Integer) || (days_old < 1)
      err = "'#{days_old}' is not a positive integer!"
      Rails.logger.error err
      raise err
    end

    Rails.logger.info "Cleaning up all deleted samples which are at least #{days_old} days old."

    deleted_samples = Sample.only_deleted.where(deleted_at: ..(Date.yesterday.midnight - days_old.day))
    deleted_samples.find_in_batches(batch_size: 50) do |deleted_samples_batch|
      deleted_samples_batch.each(&:really_destroy!)
    end
  end
end
