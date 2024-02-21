# frozen_string_literal: true

# Permanently deletes samples that have been soft deleted 'x' days ago.
class SamplesCleanupJob < ApplicationJob
  queue_as :default

  def perform(days_old: 7)
    if !days_old.instance_of?(Integer) || (days_old < 1)
      err = "'#{days_old}' is not a positive integer!"
      Rails.logger.error err
      raise err
    end

    Rails.logger.info "Cleaning up all deleted samples which are at least #{days_old} days old."
  end
end
