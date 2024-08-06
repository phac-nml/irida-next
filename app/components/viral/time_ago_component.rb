# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class TimeAgoComponent < Viral::Component
    include LocalTimeHelper
    attr_reader :time_ago, :formatted_tooltip_time

    def initialize(original_time:)
      @time_ago = distance_of_time_in_words(local_time(Time.current), local_time(original_time))
      @formatted_tooltip_time = local_time(original_time, :long)
    end
  end
end
