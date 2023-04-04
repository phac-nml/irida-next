# frozen_string_literal: true

# Clipboard Component
class ClipboardComponent < ViewComponent::Base
  def initialize(value:, description: nil)
    @value = value
    @description = description
  end
end
