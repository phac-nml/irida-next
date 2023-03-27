# frozen_string_literal: true

require 'test_helper'

class IconComponentTest < ViewComponent::TestCase
  def test_default
    render_inline(IconComponent.new(name: 'home'))
    assert_selector 'svg', count: 1
    assert_selector '[focusable="false"]', count: 1
  end

  def test_with_custom_class
    render_inline(IconComponent.new(name: 'home', classes: 'w-8 h-8'))
    assert_selector 'span.w-8.h-8', count: 1
  end
end
