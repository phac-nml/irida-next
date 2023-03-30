# frozen_string_literal: true

require 'test_helper'

module Navigation
  class HeaderComponentTest < ViewComponent::TestCase
    def test_header_component_renders_link_with_icon
      render_inline(Navigation::HeaderComponent.new(label: 'Home', icon: 'home', url: '/home'))

      assert_text 'Home'
      assert_selector 'a[href="/home"]'
      assert_selector 'svg.w-6.h-6'
    end
  end
end
