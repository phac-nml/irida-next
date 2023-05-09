# frozen_string_literal: true

class TooltipComponentPreview < ViewComponent::Preview
  def default
    render Viral::TooltipComponent.new(title: I18n.t('auth.scopes.api')) do
      content_tag(:a, 'Hover me')
    end
  end
end
