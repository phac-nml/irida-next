# frozen_string_literal: true

# Clipboard component for copying to clipboard
class ClipboardComponent < Viral::Component
  def initialize(value:, button_classes: '')
    @value = value
    @button_classes = button_classes
  end

  private

  attr_reader :value, :button_classes
end
