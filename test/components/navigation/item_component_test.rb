# frozen_string_literal: true

require 'test_helper'

module Navigation
  class ItemComponentTest < ViewComponent::TestCase
    def test_component_renders_something_useful
      render_inline Navigation::ItemComponent.new(label: 'Home', icon: 'home', url: '/home')
      assert_text 'Home'
      assert_selector 'a[href="/home"]'
      assert_selector 'svg.w-6.h-6'
    end
  end
end
