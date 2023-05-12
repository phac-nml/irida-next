# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Component
    attr_reader :button_text, :title

    renders_one :body

    def initialize(button_text:, title:)
      @button_text = button_text
      @title = title
    end
  end
end
