# frozen_string_literal: true

require 'test_helper'

class NavigationComponentTest < ViewComponent::TestCase
  test 'test should render navigation' do
    render_inline Navigation::NavigationComponent.new do |navigation|
      navigation.with_header(label: 'Home', url: '/', icon: 'home')
      navigation.with_section do |section|
        section.with_item(label: 'Dashboard', url: '/dashboard', icon: 'home')
        section.with_item(label: 'Settings', url: '/settings', icon: 'cog_6_tooth')
      end
    end

    assert_selector 'aside' do
      assert_text 'Home'
      assert_selector 'ul' do
        assert_selector 'li', count: 2
        assert_selector 'a[href="/dashboard"]'
        assert_selector 'a[href="/settings"]'
      end
    end

    assert_selector 'button[data-action="click->layout#toggle"]' do
      assert_selector 'svg.w-6.h-6'
    end
  end
end
