# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Viral form input with a prefix that can contain text or svg providing additional context to the input
      class TextInputComponent < Viral::Component
        attr_reader :form, :name, :value, :pattern, :placeholder, :required, :metadata

        renders_one :prefix

        def initialize(form:, name:, placeholder: '', value: nil, pattern: nil, required: false) # rubocop:disable Metrics/ParameterLists
          @form = form
          @name = name
          @pattern = pattern
          @placeholder = placeholder
          @required = required
          @value = value
          @metadata = metadata_header(value)
        end

        private

        def metadata_header(value)
          /metadata_[0-9]+/.match?(value.to_s) ? value : nil
        end
      end
    end
  end
end
