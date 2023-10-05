# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class TimeAgoComponent < Viral::Component
    attr_reader :time_ago, :original_time

    def initialize(original_time:)
      @time_ago = distance_of_time_in_words(Time.zone.now, original_time)
      @original_time = original_time
    end
  end
end
