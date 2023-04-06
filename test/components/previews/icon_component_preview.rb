# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview
  def with_default_arguments
    render IconComponent.new(name: 'user', classes: 'w-6 h-6')
  end

  def large_icon
    render IconComponent.new(name: 'user', classes: 'w-12 h-12')
  end
end
