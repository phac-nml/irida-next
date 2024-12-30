# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2Component < Viral::Component
    attr_reader :form, :name, :placeholder, :required, :default

    renders_many :options, Viral::Select2OptionComponent
    renders_one  :empty_state

  def initialize(form:, name:, placeholder: '', required: true, default: {})
      @form = form
      @name = name
      @placeholder = placeholder
      @required = required
      @default = default
    end
  end
end
