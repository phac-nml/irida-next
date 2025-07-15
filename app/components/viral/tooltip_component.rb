# frozen_string_literal: true

module Viral
  # A component for displaying a tooltip.
  class TooltipComponent < Component
    attr_reader :title, :title_id

    def initialize(title:, title_id: nil)
      @title = title
      @title_id = title_id || "tooltip-title-#{SecureRandom.hex(4)}"
    end
  end
end
