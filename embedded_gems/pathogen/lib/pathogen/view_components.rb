# frozen_string_literal: true

require 'pathogen/view_components/version'
require 'pathogen/view_components/engine'
require 'pathogen/view_helper'
require 'pathogen/styles/form_styles'

module Pathogen
  # Convenience module that includes all Pathogen helpers at once.
  #
  # This module provides a single include statement to access all Pathogen helper methods
  # for rendering icons, badges, forms, and other UI components with Pathogen styling.
  #
  # Includes:
  # - Pathogen::ViewHelper: Core view helpers (pathogen_icon, pathogen_badge, etc.)
  # - Pathogen::FormHelper: Form builder helpers with Pathogen styling
  # - Pathogen::FormTagHelper: Form tag helpers with Pathogen styling
  #
  # @example Include all helpers in a ViewComponent
  #   class MyComponent < ViewComponent::Base
  #     include Pathogen::Helpers
  #
  #     def call
  #       pathogen_icon(:check, size: :md, color: :blue)
  #     end
  #   end
  #
  # @example Include in a Rails helper
  #   module ApplicationHelper
  #     include Pathogen::Helpers
  #   end
  module Helpers
    def self.included(base)
      base.include Pathogen::ViewHelper
      base.include Pathogen::FormHelper
      base.include Pathogen::FormTagHelper
    end
  end

  # :nodoc:
  module ViewComponents
    DEPRECATION_HORIZON = '1.0'

    # flowbit/pathogen_components root directorey
    def self.root
      Pathname(File.expand_path(File.join('..', '..'), __dir__))
    end

    # Skip coverage here because only one branch will execute depending on what
    # Rails version you're running.

    # :nocov:
    def self.deprecation
      @deprecation ||=
        if Rails.application.respond_to?(:deprecators)
          Rails.application.deprecators[:pathogen_view_components] ||= ActiveSupport::Deprecation.new(
            DEPRECATION_HORIZON, 'pathogen_view_components'
          )
        else
          ActiveSupport::Deprecation.instance
        end
    end
    # :nocov:
  end
end
