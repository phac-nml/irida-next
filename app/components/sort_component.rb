# frozen_string_literal: true

# Component for sort in table headers
class SortComponent < Component
  attr_reader :label, :field, :url, :system_arguments

  def initialize(sort:, label:, url:, field:, **system_arguments)
    @sort_key, @sort_direction = sort.split
    @label = label
    @url = url
    @field = field
    @system_arguments = system_arguments
  end

  def icon
    return unless @sort_key.to_s == URI.encode_www_form_component(@field.to_s)

    @sort_direction == 'asc' ? 'arrow_up' : 'arrow_down'
  end
end
