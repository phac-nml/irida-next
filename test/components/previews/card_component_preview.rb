# frozen_string_literal: true

class CardComponentPreview < ViewComponent::Preview
  def default
    render Viral::CardComponent.new(element: 'section') do
      'This is a card'
    end
  end
end
