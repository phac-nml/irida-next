# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# main module for Irida application
module Irida
  # main application class
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << Rails.root.join('lib')

    # Skip adding routes when generating a controller since we have broken
    # our routes into separate files.
    config.generators do |g|
      g.skip_routes true
    end

    initializer 'app_assets', after: 'importmap.assets' do
      Rails.application.config.assets.paths << Rails.root.join('app') # for component sidecar js
    end

    # Sweep importmap cache for components
    config.importmap.cache_sweepers << Rails.root.join('app/components')

    config.view_component.default_preview_layout = 'lookbook'

    # Version has_many and belongs_to associations (This feature is experimental due to the number of edge cases)
    # config.logidze.associations_versioning = true

    # Only load log data on demand
    config.logidze.ignore_log_data_by_default = true

    initializer 'catch_all', after: :add_internal_routes, before: :set_routes_reloader_hook do |app|
      routes_reloader.run_after_load_paths = lambda {
        app.routes.append do
          match '*unmatched', to: 'application#route_not_found', via: :all
        end
      }
    end

    # Only enables en and fr locales, avoiding unnecessarily loading other locales
    config.i18n.available_locales = %i[en fr]
    # Set default locale
    config.i18n.default_locale = :en

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :good_job
    # good_job configuration
    config.good_job.enable_cron = ENV.fetch('ENABLE_CRON', 'true') == 'true'
    # Configure cron with a hash that has a unique key for each recurring job
    config.good_job.cron = {
      attachments_cleanup_task: {
        cron: '0 1 * * *', # Daily, 1 AM
        class: 'AttachmentsCleanupJob', # job class as a String, must be an ActiveJob job
        kwargs: { days_old: 7 }, # number of days old an attachment must be for deletion
        description: 'Permanently deletes attachments that have been soft-deleted some time ago.'
      },
      samples_cleanup_task: {
        cron: '0 2 * * *', # Daily, 2 AM
        class: 'SamplesCleanupJob', # job class as a String, must be an ActiveJob job
        kwargs: { days_old: 7 }, # number of days old a sample must be for deletion
        description: 'Permanently deletes samples that have been soft-deleted some time ago.'
      },
      data_exports_cleanup_task: {
        cron: '0 3 * * *', # Daily, 3 AM
        class: 'DataExports::CleanupJob', # job class as a String, must be an ActiveJob job
        description: 'Permanently deletes expired data exports.'
      }
    }

    # Omniauth Configuration
    config.auth_config = config_for(Rails.root.join('config/authentication/auth_config.yml'))

    # GA4GH WES Configuration
    config.ga4gh_wes_server_endpoint = if Rails.application.credentials.ga4gh_wes.nil?
                                         nil
                                       else
                                         Rails.application.credentials.dig(:ga4gh_wes, :server_url_endpoint)
                                       end
  end
end
