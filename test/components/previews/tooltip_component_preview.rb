# frozen_string_literal: true

class TooltipComponentPreview < ViewComponent::Preview
  def default
    render Viral::TooltipComponent.new(title: 'I am a really good tooltip') do
      content_tag(:button, 'Hover me', class: 'btn btn-default')
    end
  end
end
