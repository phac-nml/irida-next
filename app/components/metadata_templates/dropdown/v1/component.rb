# frozen_string_literal: true

module MetadataTemplates
  module Dropdown
    module V1
      # Dropdown component for metadata templates
      class Component < ::Component
        attr_reader :url

        def initialize(url:)
          @url = url
        end
      end
    end
  end
end
