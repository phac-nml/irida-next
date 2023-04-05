# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview
  def default
    render Viral::IconComponent.new(name: 'user')
  end

  def primary
    render Viral::IconComponent.new(name: 'user', color: :primary)
  end

  def critical
    render Viral::IconComponent.new(name: 'user', color: :critical)
  end
end
