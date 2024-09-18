# frozen_string_literal: true

# Token component for displaying a token
class TokenComponent < Component
  attr_reader :value, :label

  def initialize(value:, aria_label:, **system_arguments)
    @value = value
    @label = aria_label
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      'flex'
    )
  end
end
