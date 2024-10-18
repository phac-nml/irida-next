require 'rails/engine'
require 'view_component'
require 'view_component/version'

module Flowbite
  module ViewComponents
    # :nodoc:
    class Engine < ::Rails::Engine
      isolate_namespace Flowbite::ViewComponents

      config.autoload_paths = %W[
        #{root}/lib
      ]

      config.eager_load_paths = %W[
        #{root}/app/components
        #{root}/app/helpers
        #{root}/app/lib
      ]

      config.flowbite_view_components = ActiveSupport::OrderedOptions.new

      config.flowbite_view_components.raise_on_invalid_options = false
      config.flowbite_view_components.silence_deprecations = false
      config.flowbite_view_components.validate_class_names = !Rails.env.production?
      config.flowbite_view_components.raise_on_invalide_aria = false

      initializer 'flowbite_view_components.assets' do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += %w[
            flowbite_view_components
          ]
        end
      end
    end
  end
end
