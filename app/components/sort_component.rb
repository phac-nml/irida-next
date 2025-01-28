# frozen_string_literal: true

# Component for sort in table headers
class SortComponent < Component
  attr_reader :label, :field, :url, :system_arguments

  def initialize(sort:, label:, url:, field:, **system_arguments)
    # use rpartition to split on the first space encountered from the right side
    # this allows us to sort by metadata fields which contain spaces
    @sort_key, _space, @sort_direction = sort.rpartition(' ')
    @label = label
    @url = url
    @field = field
    @system_arguments = system_arguments
  end

  def icon
    return unless @sort_key.to_s == @field.to_s

    @sort_direction == 'asc' ? 'arrow_up' : 'arrow_down'
  end
end
