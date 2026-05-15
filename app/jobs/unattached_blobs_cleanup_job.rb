# frozen_string_literal: true

# delete/destroy blobs that have been unattached for X days ago
class UnattachedBlobsCleanupJob < ApplicationJob
  queue_as :default
  queue_with_priority 50

  # Finds all unattached blobs more than `days_old`` days old, and destroys them
  # Params:
  # +days_old+:: positive integer. Number of days old and older to destroy. Default is 1
  def perform(days_old: 1)
    if !days_old.instance_of?(Integer) || (days_old < 1)
      err = "'#{days_old}' is not a positive integer!"
      Rails.logger.error err
      raise err
    end

    Rails.logger.info "Cleaning up all unattached blobs which are at least #{days_old} days old."

    blobs_to_delete = ActiveStorage::Blob.unattached.where(created_at: ..(Date.yesterday.midnight - days_old.day))
    blobs_to_delete.find_in_batches(batch_size: 50) do |group|
      group.each(&:purge_later)
    end
  end
end
