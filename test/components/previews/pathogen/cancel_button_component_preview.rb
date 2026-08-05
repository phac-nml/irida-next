# frozen_string_literal: true

module Pathogen
  class CancelButtonComponentPreview < ViewComponent::Preview
    # @label Default
    def default
      render(Pathogen::CancelButtonComponent.new)
    end

    # @label As link
    def with_href
      render(Pathogen::CancelButtonComponent.new(href: '#'))
    end

    # @label Custom label
    def with_custom_label
      render(Pathogen::CancelButtonComponent.new(label: 'Go back'))
    end
  end
end
