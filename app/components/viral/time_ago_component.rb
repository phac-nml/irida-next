# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class TimeAgoComponent < Viral::Component
    attr_reader :time_ago, :original_time

    def initialize(original_time:, current_time: Time.zone.now)
      original_time = original_time.to_datetime if original_time.is_a?(String)
      @time_ago = distance_of_time_in_words(current_time, original_time)
      @original_time = original_time
    end
  end
end
