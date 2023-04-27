# frozen_string_literal: true

# Clipboard component for copying text to clipboard
class ClipboardComponent < Component
  attr_reader :value

  def initialize(value:, **system_arguments)
    @value = value
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      'flex'
    )
  end
end
