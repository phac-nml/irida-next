# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Checkbox component with a prefix
      class CheckboxComponent < Viral::Component
        attr_reader :form, :name, :value, :checked, :label

        renders_one :prefix

        def initialize(form:, name:, value:, checked:, label:)
          @form = form
          @name = name
          @value = value
          @label = label
          @checked = checked
        end
      end
    end
  end
end
