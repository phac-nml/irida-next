# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class DistanceOfTimeComponent < Viral::Component
    attr_reader :time_difference, :original_time

    def initialize(current_time:, original_time:)
      @time_difference = distance_of_time_in_words(current_time, original_time)
      @original_time = original_time
    end
  end
end
