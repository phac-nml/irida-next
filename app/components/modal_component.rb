# frozen_string_literal: true

# A component for displaying a modal.
class ModalComponent < Component
  attr_reader :button_text, :title, :body

  def initialize(button_text:, title:, body:)
    @button_text = button_text
    @title = title
    @body = body
  end
end
