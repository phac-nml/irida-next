# frozen_string_literal: true

module Viral
  # This component is a container for the tabs.
  class ProgressBarComponent < Viral::Component
    attr_reader :items_to_complete

    def initialize(items_to_complete:)
      @items_to_complete = items_to_complete
    end
  end
end
