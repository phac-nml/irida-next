# frozen_string_literal: true

# Clipboard Component
class ClipboardComponent < ViewComponent::Base
  def initialize(value:, label: nil)
    @value = value
    @label = label
  end
end
