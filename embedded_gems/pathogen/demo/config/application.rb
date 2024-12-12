# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'
require 'pathogen/view_components'
require 'pathogen/view_components/engine'
require 'view_component'
require 'lookbook'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Demo
  # :nodoc:
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

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
    #
    config.hotwire_livereload.disable_default_listeners = true
    config.hotwire_livereload.listen_paths = [
      Rails.root.join('app/assets/stylesheets'),
      Rails.root.join('app/javascript'),
      Rails.root.join('test/components')
    ]

    # Initialize configuration defaults for originally generated Rails version.
    config.view_component.default_preview_layout = 'component_preview'
    config.view_component.show_previews = true
    config.view_component.preview_controller = 'PreviewController'
    config.view_component.preview_paths << Rails.root.join('../previews')
    config.lookbook.ui_theme = 'zinc'

    config.lookbook.project_name = "Pathogen ViewComponents v#{Pathogen::ViewComponents::VERSION::STRING}"
    config.lookbook.component_paths = [
      Pathogen::ViewComponents::Engine.root.join('app', 'components')
    ]
    config.lookbook.preview_display_options = {
      theme: %w[light dark]
    }
    config.lookbook.page_paths = [Pathogen::ViewComponents::Engine.root.join('docs', 'pages')]
  end
end
