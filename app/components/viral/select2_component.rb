# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2Component < Viral::Component
    attr_reader :form, :name

    renders_many :options, Viral::Select2OptionComponent
    renders_one  :empty_state

    def initialize(form:, name:)
      @form = form
      @name = name
    end
  end
end
