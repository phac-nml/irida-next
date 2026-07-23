# frozen_string_literal: true

module MetadataTemplates
  module Dropdown
    module V1
      # Dropdown component for metadata templates
      class Component < ::Component
        attr_reader :url

        def initialize(url:, toolbar_item: false)
          @url = url
          @toolbar_item = toolbar_item
        end

        def dropdown_system_arguments
          return {} unless @toolbar_item

          {
            tabindex: -1,
            data: {
              'pathogen--toolbar-target': 'item'
            }
          }
        end

        def button_classes
          if @toolbar_item
            helpers.pathogen_toolbar_trigger_classes
          else
            'button w-full button-default'
          end
        end
      end
    end
  end
end
