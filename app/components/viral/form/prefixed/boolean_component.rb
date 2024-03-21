# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Render a truthy radio component
      class BooleanComponent < Viral::Component
        attr_reader :form, :name, :value, :label

        renders_one :prefix

        def initialize(form:, name:, value:, label:)
          @form = form
          @name = name
          @value = value
          @label = label
        end
      end
    end
  end
end
