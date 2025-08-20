# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Render a truthy radio component
      class BooleanComponent < Viral::Component
        attr_reader :form, :name, :value

        renders_one :prefix
        renders_one :legend, lambda { |classes: nil, &block|
          content_tag :legend, class: classes, &block
        }

        def initialize(form:, name:, value:)
          @form = form
          @name = name
          @value = value
        end
      end
    end
  end
end
