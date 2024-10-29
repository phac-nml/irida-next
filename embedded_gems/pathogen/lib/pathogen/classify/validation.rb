# frozen_string_literal: true

require_relative 'utilities'

module Pathogen
  class Classify
    # :nodoc:
    class Validation
      INVALID_CLASS_NAME_PREFIXES = /text-|box-shadow-|box_shadow-/

      class << self
        def invalid?(class_name)
          class_name.start_with?(INVALID_CLASS_NAME_PREFIXES) ||
            Pathogen::Classify::Utilities.supported_selector?(class_name)
        end
      end
    end
  end
end
