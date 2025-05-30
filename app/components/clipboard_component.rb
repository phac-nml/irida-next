# frozen_string_literal: true

# Clipboard component for copying to clipboard
class ClipboardComponent < Viral::Component
  def initialize(value:, title:, button_classes: '', button_name: nil)
    @value = value
    @title = title
    @button_classes = class_names(button_classes, 'cursor-pointer ml-1')
    @button_name = button_name || "clipboard-button-#{SecureRandom.hex(4)}"
  end

  private

  attr_reader :value, :button_classes, :button_name, :title
end
