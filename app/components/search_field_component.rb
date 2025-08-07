# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  def initialize(label:, form:, field_name:)
    @label = label
    @form = form
    @field_name = field_name
  end
end
