# frozen_string_literal: true

require 'rails/railtie'

module Pathogen
  module ViewComponents
    # :nodoc:
    class Railtie < ::Rails::Railtie
      # Load the button helper
      config.before_initialize do
        require 'pathogen/button_helper'
      end

      # Include the helper in ActionView
      initializer 'pathogen_view_components.helpers' do |app|
        ActiveSupport.on_load(:action_view) do
          include Pathogen::ButtonHelper
        end
      end
    end
  end
end
