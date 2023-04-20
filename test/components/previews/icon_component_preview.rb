# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview
  def default
    render Viral::IconComponent.new(name: 'user')
  end

  def larger_size_icon
    render Viral::IconComponent.new(name: 'user', classes: 'w-16 h-16')
  end

  def primary
    render Viral::IconComponent.new(name: 'user', color: :primary)
  end

  def critical
    render Viral::IconComponent.new(name: 'user', color: :critical)
  end

  def subdued
    render Viral::IconComponent.new(name: 'user', color: :subdued)
  end

  def warning
    render Viral::IconComponent.new(name: 'user', color: :warning)
  end

  def success
    render Viral::IconComponent.new(name: 'user', color: :success)
  end
end
