# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2Component < Viral::Component
    attr_reader :form, :name, :required

    renders_many :options, Viral::Select2OptionComponent
    renders_one  :empty_state

    def initialize(form:, name:, required: true)
      @form = form
      @name = name
      @required = required
    end
  end
end
