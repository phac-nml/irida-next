# frozen_string_literal: true

require 'rails/engine'
require 'view_component'
require 'view_component/version'

module Pathogen
  module ViewComponents
    # :nodoc:
    class Engine < ::Rails::Engine
      isolate_namespace Pathogen::ViewComponents

      config.autoload_paths = %W[
        #{root}/lib
      ]

      config.eager_load_paths = %W[
        #{root}/app/components
        #{root}/app/helpers
        #{root}/app/lib
      ]

      config._view_components = ActiveSupport::OrderedOptions.new

      config._view_components.raise_on_invalid_options = false
      config._view_components.silence_deprecations = false
      config._view_components.validate_class_names = !Rails.env.production?
      config._view_components.raise_on_invalide_aria = false

      initializer '_view_components.assets' do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += %w[
            _view_components
          ]
        end
      end
    end
  end
end
