# frozen_string_literal: true

# This component is used to create a dynamic dropdown menu.
# The contents of the dropdown are to be updated via turbo-stream.
class DynamicDropdownComponent < Component
  attr_reader :id, :label, :url, :current_value

  def initialize(id:, label:, url:, current_value:)
    @id = id
    @label = label
    @url = url
    @current_value = current_value
  end
end
