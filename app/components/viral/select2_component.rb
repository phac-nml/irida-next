# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2Component < Viral::Component
    attr_reader :form, :name, :id, :placeholder, :required, :selected_value, :aria_describedby, :aria_invalid,
                :aria_required, :field_hint

    renders_many :options, Viral::Select2OptionComponent
    renders_one  :empty_state

    # rubocop:disable Metrics/ParameterLists
    def initialize(form:, name:, id:, placeholder: '', required: true, selected_value: '',
                   aria_invalid: false, field_hint: false)
      @form = form
      @name = name
      @id = id
      @placeholder = placeholder
      @required = required
      @selected_value = selected_value.presence
      @aria_invalid = aria_invalid
      @aria_required = required
      @field_hint = field_hint
      @aria_describedby = construct_aria_describedby
    end
    # rubocop:enable Metrics/ParameterLists

    def construct_aria_describedby
      constructed_aria_describedby = []
      constructed_aria_describedby << form.field_id(@name, 'error') if @aria_invalid
      constructed_aria_describedby << form.field_id(@name, 'hint') if @field_hint

      return constructed_aria_describedby.join(' ') if constructed_aria_describedby.length.positive?

      nil
    end
  end
end
