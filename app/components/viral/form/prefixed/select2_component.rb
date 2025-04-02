# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Select2 component with a prefix
      class Select2Component < ViewComponent::Base
        attr_reader :form, :id, :name, :selected_value, :placeholder, :required

        renders_many :options, Viral::Select2OptionComponent
        renders_one :empty_state

        def initialize(form:, id:, name:, selected_value: false, **options)
          @form = form
          @name = name
          @id = id
          @selected_value = selected_value
          @placeholder = options[:placeholder]
          @required = options[:required]
        end
      end
    end
  end
end
