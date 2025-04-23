# frozen_string_literal: true

# delete/destroy attachements that have been deleted X days ago
class AttachmentsCleanupJob < ApplicationJob
  queue_as :default
  queue_with_priority 50

  # Finds all deleted attachments more than `days_old`` days old, and destroys them
  # Params:
  # +days_old+:: positive integer. Number of days old and older to destroy. Default is 7
  def perform(days_old: 7)
    if !days_old.instance_of?(Integer) || (days_old < 1)
      err = "'#{days_old}' is not a positive integer!"
      Rails.logger.error err
      raise err
    end

    Rails.logger.info "Cleaning up all deleted attachments which are at least #{days_old} days old."

    # SELECT "attachments".* FROM "attachments"
    #   WHERE "attachments"."deleted_at" IS NOT NULL AND "attachements"."deleted_at" <= $1
    attachments_to_delete = Attachment.only_deleted.where(deleted_at: ..(Date.yesterday.midnight - days_old.day))
    attachments_to_delete.find_in_batches(batch_size: 50) do |group|
      group.each do |att|
        att.file.purge
        att.really_destroy!
      end
    end
  end
end
