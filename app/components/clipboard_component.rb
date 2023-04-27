# frozen_string_literal: true

# Clipboard component for copying text to clipboard
class ClipboardComponent < Component
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
