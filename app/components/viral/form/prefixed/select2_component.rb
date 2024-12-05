# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Select2 component with a prefix
      class Select2Component < ViewComponent::Base
        attr_reader :form, :name, :selected_value, :placeholder, :required

        renders_many :options, Viral::Select2OptionComponent
        renders_one :empty_state

        def initialize(form:, name:, selected_value: false, placeholder: '', required: true)
          @form = form
          @name = name
          @selected_value = selected_value
          @placeholder = placeholder
          @required = required
        end
      end
    end
  end
end
