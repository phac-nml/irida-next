# frozen_string_literal: true

module Navigation
  class ItemComponent < ViewComponent::Base
    def initialize(label:, icon:, url:)
      @label = label
      @icon = icon
      @url = url
    end
  end
end
