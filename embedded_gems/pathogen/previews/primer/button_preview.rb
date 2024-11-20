# frozen_string_literal: true

module Primer
  # Preview class for Primer::Button component
  class ButtonPreview < ViewComponent::Preview
    # @label Default
    def default
      render Primer::Button.new do
        'Shit'
      end
    end
  end
end
