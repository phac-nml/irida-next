require 'flowbite/view_components/version'
require 'flowbite/view_components/engine'

module Flowbite
  # :nodoc:
  module ViewComponents
    DEPRECATION_HORIZON = '1.0'.freeze

    # flowbit/view_components root directorey
    def self.root
      Pathname(File.expand_path(File.join('..', '..'), __dir__))
    end

    # Skip coverage here because only one branch will execute depending on what
    # Rails version you're running.

    # :nocov:
    def self.deprecation
      @deprecation ||=
        if Rails.application.respond_to?(:deprecators)
          Rails.application.deprecators[:primer_view_components] ||= ActiveSupport::Deprecation.new(
            DEPRECATION_HORIZON, 'flowbite_view_components'
          )
        else
          ActiveSupport::Deprecation.instance
        end
    end
    # :nocov:
  end
end
