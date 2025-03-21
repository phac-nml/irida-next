# frozen_string_literal: true

# Clipboard component for copying to clipboard
class ClipboardComponent < Viral::Component
  def initialize(value:, button_classes: '')
    @value = value
    @button_classes = class_names(button_classes, 'cursor-pointer ml-1')
  end

  private

  attr_reader :value, :button_classes
end
