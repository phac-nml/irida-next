# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  def initialize(label:, placeholder:, form:, field_name:, has_search_results: false)
    @label = label
    @placeholder = placeholder
    @form = form
    @field_name = field_name
    @has_search_results = has_search_results
  end

  def clear_button?
    @has_search_results
  end
end
