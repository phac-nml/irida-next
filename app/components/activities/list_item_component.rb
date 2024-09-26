# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < Component
    attr_accessor :activity

    def initialize(activity: nil, pagy: nil)
      @activity = activity
      @pagy = pagy
    end
  end
end
