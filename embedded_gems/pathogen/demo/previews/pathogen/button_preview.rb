# frozen_string_literal: true

module Pathogen
  class ButtonPreview < ViewComponent::Preview
    # @label Default
    def default
      render Pathogen::Button.new do
        "Don't click me"
      end
    end
  end
end
