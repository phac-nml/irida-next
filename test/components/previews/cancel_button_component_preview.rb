# frozen_string_literal: true

class CancelButtonComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(CancelButtonComponent.new)
  end

  # @label As link
  def with_href
    render(CancelButtonComponent.new(href: '#'))
  end

  # @label Custom label
  def with_custom_label
    render(CancelButtonComponent.new(label: 'Go back'))
  end
end
