# frozen_string_literal: true

module Pathogen
  # Preview class for Primer::Button component
  class ButtonPreview < ViewComponent::Preview
    # @label Default
    def default
      render Pathogen::Button.new do
        'Shit'
      end
    end
  end
end
