# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class TimeAgoComponent < Viral::Component
    attr_reader :original_time

    def initialize(original_time:)
      @original_time = original_time
    end
  end
end
