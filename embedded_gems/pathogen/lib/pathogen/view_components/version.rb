# frozen_string_literal: true

module Pathogen
  module ViewComponents
    module Version
      MAJOR = 0
      MINOR = 1
      PATCH = 0

      STRING = [MAJOR, MINOR, PATCH].join('.').freeze
    end
  end
end

Rails.logger.debug Pathogen::ViewComponents::Version::STRING if __FILE__ == $PROGRAM_NAME
