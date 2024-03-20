# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Select component with a prefix
      class SelectComponent < Viral::Component
        attr_reader :form, :name, :options, :selected_value

        renders_one :prefix

        def initialize(form:, name:, options: [], selected_value: false)
          @form = form
          @name = name
          @options = options
          @selected_value = selected_value
        end
      end
    end
  end
end
