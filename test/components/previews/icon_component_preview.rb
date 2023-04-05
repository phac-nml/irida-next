# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview
  def default
    render Viral::IconComponent.new(name: 'user')
  end

  def colored
    render Viral::IconComponent.new(name: 'user', color: :primary)
  end
end
