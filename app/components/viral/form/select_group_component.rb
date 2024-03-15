# frozen_string_literal: true

class Viral::Form::SelectGroupComponent < Viral::Component
  attr_reader :form, :name, :options, :selected_value

  renders_one :prefix

  def initialize(form:, name:, options: [], selected_value: false)
    @form = form
    @name = name
    @options = options
    @selected_value = selected_value
  end
end
