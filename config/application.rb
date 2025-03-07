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
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

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

    # Omniauth Configuration
    config.auth_config = config_for(Rails.root.join('config/authentication/auth_config.yml'))

    # GA4GH WES Configuration
    config.ga4gh_wes_server_endpoint = if Rails.application.credentials.ga4gh_wes.nil? || ENV.key?('GA4GH_WES_URL')
                                         ENV.fetch('GA4GH_WES_URL', nil)
                                       else
                                         Rails.application.credentials.dig(:ga4gh_wes, :server_url_endpoint)
                                       end

    ActiveRecord::SessionStore::Session.serializer = :json

    # index nested attribute errors
    config.active_record.index_nested_attribute_errors = true
  end
end

require 'view_component'
require 'pathogen/view_components'
