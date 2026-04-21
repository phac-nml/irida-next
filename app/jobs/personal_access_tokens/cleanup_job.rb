# frozen_string_literal: true

module PersonalAccessTokens
  # Queues the personal access token cleanup job
  class CleanupJob < ApplicationJob
    queue_as :default
    queue_with_priority 50

    def perform
      Rails.logger.info 'Cleaning up all inactive (revoked and expired) personal access tokens'

      inactive_as_of_days_ago = Irida::CurrentSettings.current_application_settings.cleanup_inactive_access_tokens_after_days
      cutoff_date = inactive_as_of_days_ago.days.ago.to_date

      inactive_tokens = PersonalAccessToken.where(revoked: true, updated_at: ..cutoff_date).or(
        PersonalAccessToken.where(revoked: false).where.not(expires_at: nil).where(expires_at: ..cutoff_date)
      )

      inactive_tokens.find_in_batches(batch_size: 50) do |inactive_tokens_batch|
        inactive_tokens_batch.each(&:really_destroy!)
      end
    end
  end
end
