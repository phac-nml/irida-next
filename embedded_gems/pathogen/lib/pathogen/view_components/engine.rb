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

      # Configure asset paths to include JavaScript assets
      config.assets.paths << root.join('app/assets/javascripts')

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

    end
  end
end
