# frozen_string_literal: true

module Viral
  # A component for displaying a tooltip.
  class TooltipComponent < Component
    attr_reader :title

    def initialize(title:)
      @title = title
    end
  end
end
