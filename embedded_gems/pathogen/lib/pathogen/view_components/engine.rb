# frozen_string_literal: true

require 'rails/engine'
require 'view_component'
require 'view_component/version'
require_relative '../view_helper'
require_relative '../form_helper'
require_relative '../form_tag_helper'

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
        #{root}/app/lib
      ]

      # Set options for ViewComponent
      config.view_component.raise_on_invalid_options = false
      config.view_component.silence_deprecations = false
      config.view_component.validate_class_names = !Rails.env.production?
      config.view_component.raise_on_invalid_aria = !Rails.env.production?

      initializer 'pathogen.view_components' do
        ActiveSupport.on_load(:action_view) do
          include Pathogen::ViewHelper
          include Pathogen::FormHelper
          include Pathogen::FormTagHelper
        end
      end

      initializer 'pathogen.assets', before: 'importmap.assets' do |app|
        # Add engine's JavaScript paths to asset pipeline
        app.config.assets.paths << root.join('app/javascript/controllers')

        # Precompile pathogen controller files for production
        app.config.assets.precompile += %w[
          pathogen/tabs_controller.js
          pathogen/tooltip_controller.js
          pathogen/datepicker/input_controller.js
          pathogen/datepicker/calendar_controller.js
          pathogen/datepicker/utils.js
          pathogen/datepicker/constants.js
        ]
      end

      initializer 'pathogen.importmap', before: 'importmap' do |app|
        # Register this engine's importmap configuration
        app.config.importmap.paths << root.join('config/importmap.rb')

        # Register cache sweepers for development mode
        app.config.importmap.cache_sweepers << root.join('app/assets/javascripts')
        app.config.importmap.cache_sweepers << root.join('app/javascript/controllers')
      end
    end
  end
end
