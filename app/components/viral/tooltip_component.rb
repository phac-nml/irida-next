# frozen_string_literal: true

module Viral
  # A component for displaying a tooltip.
  class TooltipComponent < Component
    attr_reader :title, :button_name

    def initialize(title:, button_name: nil)
      @title = title
      @button_name = button_name || "tooltip-button-#{SecureRandom.hex(4)}"
    end
  end
end
