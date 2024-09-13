# frozen_string_literal: true

# Clipboard component for copying to clipboard
class ClipboardComponent < Component
  attr_reader :value

  renders_one :button

  def initialize(value: nil)
    @value = value
  end
end
