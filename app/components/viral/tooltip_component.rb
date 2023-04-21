# frozen_string_literal: true

module Viral
  class TooltipComponent < Component
    attr_reader :title

    def initialize(title:)
      @title = title
    end
  end
end
