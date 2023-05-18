# frozen_string_literal: true

class ButtonComponentPreview < ViewComponent::Preview
  def basic
    render Viral::ButtonComponent.new do
      'Button'
    end
  end

  def primary
    render Viral::ButtonComponent.new(type: :primary) do
      'Primary Button'
    end
  end

  def destructive
    render Viral::ButtonComponent.new(type: :destructive) do
      'Destructive Button'
    end
  end

  def small
    render Viral::ButtonComponent.new(size: :small) do
      'Small Button'
    end
  end

  def large
    render Viral::ButtonComponent.new(size: :large) do
      'Large Button'
    end
  end

  def full_width
    render Viral::ButtonComponent.new(full_width: true) do
      'Full Width Button'
    end
  end
end
