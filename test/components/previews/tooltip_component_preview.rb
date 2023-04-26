# frozen_string_literal: true

class TooltipComponentPreview < ViewComponent::Preview
  def default
    render Viral::TooltipComponent.new(title: I18n.t('auth.scopes.api')) do
      content_tag(:button, 'Hover me', class: 'btn btn-default')
    end
  end
end
