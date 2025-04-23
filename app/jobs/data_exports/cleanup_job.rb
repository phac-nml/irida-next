# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CleanupJob < ApplicationJob
    queue_as :default
    queue_with_priority 50

    def perform
      Rails.logger.info 'Cleaning up all expired data exports'

      expired_exports = DataExport.where(expires_at: ..Date.current.midnight)
      expired_exports.find_in_batches(batch_size: 50) do |expired_exports_batch|
        expired_exports_batch.each(&:destroy)
      end
    end
  end
end
