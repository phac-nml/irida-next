# frozen_string_literal: true

Rails.application.configure do
  # good_job configuration
  config.good_job.enable_cron = ENV.fetch('ENABLE_CRON', 'true') == 'true'
  cron_cleanup_after_days = ENV.fetch('CRON_CLEANUP_AFTER_DAYS', '7')
  # Configure cron with a hash that has a unique key for each recurring job
  config.good_job.cron = {
    attachments_cleanup_task: {
      cron: '0 1 * * *', # Daily, 1 AM
      class: 'AttachmentsCleanupJob', # job class as a String, must be an ActiveJob job
      kwargs: { days_old: cron_cleanup_after_days.to_i }, # number of days old an attachment must be for deletion
      description: 'Permanently deletes attachments that have been soft-deleted some time ago.'
    },
    samples_cleanup_task: {
      cron: '0 2 * * *', # Daily, 2 AM
      class: 'SamplesCleanupJob', # job class as a String, must be an ActiveJob job
      kwargs: { days_old: cron_cleanup_after_days.to_i }, # number of days old a sample must be for deletion
      description: 'Permanently deletes samples that have been soft-deleted some time ago.'
    },
    data_exports_cleanup_task: {
      cron: '0 3 * * *', # Daily, 3 AM
      class: 'DataExports::CleanupJob', # job class as a String, must be an ActiveJob job
      description: 'Permanently deletes expired data exports.'
    }
  }
end

GoodJob.active_record_parent_class = 'JobsRecord'
