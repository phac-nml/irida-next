# frozen_string_literal: true

# Component to render activity
class InlineEditComponent < Component
  attr_accessor :url, :input_name, :value

  def initialize(url:, input_name:, value:)
    @url = url
    @input_name = input_name
    @value = value
  end
end
