# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Viral form input with a prefix that can contain text or svg providing additional context to the input
      class TextInputComponent < Viral::Component
        attr_reader :form, :name, :value, :pattern, :placeholder, :required

        renders_one :prefix

        # rubocop:disable Metrics/ParameterLists
        def initialize(form:, name:, placeholder: '', value: nil, pattern: nil, required: false)
          @form = form
          @name = name
          @pattern = pattern
          @placeholder = placeholder
          @required = required
          @value = value
        end

        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
