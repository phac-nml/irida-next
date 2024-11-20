# frozen_string_literal: true
class ButtonPreview < ViewComponent::Preview
  # @!group Basic

  # @label Default
  def default
    render Pathogen::Button.new do
      "Click me friend"
    end
  end
end
