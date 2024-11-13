# frozen_string_literal: true

require_relative 'boot'

require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_model/railtie'
require 'sprockets/railtie'
require 'view_component'
require 'pathogen/view_components'
require 'pathogen/view_components/engine'
require 'heroicon-rails'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Demo
  # :nocov:
  class Application < Rails::Application
    if Rails.version.to_i >= 7.1
      config.load_defaults 7.1
    elsif Rails.version.to_i >= 7
      config.load_defaults 7.0
    elsif Rails.version.to_i >= 6
      config.load_defaults 6.0
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.view_component.default_preview_layout = 'component_preview'
    config.view_component.show_previews = true
    config.view_component.preview_controller = 'PreviewController'
    config.view_component.preview_paths << Rails.root.join('../previews')

    config.action_dispatch.default_headers.clear

    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => %w[GET].join(',')
    }

    if config.respond_to?(:lookbook)
      asset_panel_config = {
        label: 'Assets',
        partial: 'lookbook/panels/assets',
        locals: lambda do |data|
          assets = data.preview.components.flat_map do |component|
            asset_files = Dir[Primer::ViewComponents.root.join('app', 'components',
                                                               "#{component.relative_file_path.to_s.chomp('.rb')}.{css,ts}")]
            asset_files.map do |path_str|
              path = Pathname(path_str)
              { path: path, language: path.extname == '.ts' ? :js : :css }
            end
          end

          { assets: assets }
        end
      }
      Lookbook.define_panel('assets', asset_panel_config)

      config.lookbook.project_name = "Pathogen ViewComponents v#{Pathogen::ViewComponents::VERSION::STRING}"
      config.lookbook.preview_display_options = {
        theme: [
          ['Light default', 'light'],
          ['Dark default', 'dark'],
          ['All themes', 'all']
        ]
      }

      config.lookbook.preview_embeds.policy = 'ALLOWALL'
      config.lookbook.page_paths = [Rails.root.join('../previews/pages')]
      config.lookbook.component_paths = [Pathogen::ViewComponents::Engine.root.join('app', 'components')]
    end
  end
end
