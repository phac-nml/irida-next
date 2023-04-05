# frozen_string_literal: true

require 'test_helper'

module Viral
  class IconComponentTest < ViewComponent::TestCase
    test 'default' do
      render_inline(Viral::IconComponent.new(name: 'home'))
      assert_selector 'svg.Viral-Icon__Svg', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with custom class' do
      render_inline(Viral::IconComponent.new(name: 'home', classes: 'w-8 h-8'))
      assert_selector 'span.Viral-Icon.w-8.h-8', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with subdued color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :subdued))
      assert_selector 'span.Viral-Icon.Viral-Icon--colorSubdued', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with critical color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :critical))
      assert_selector 'span.Viral-Icon.Viral-Icon--colorCritical', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with warning color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :warning))
      assert_selector 'span.Viral-Icon.Viral-Icon--colorWarning', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with success color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :success))
      assert_selector 'span.Viral-Icon.Viral-Icon--colorSuccess', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with primary color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :primary))
      assert_selector 'span.Viral-Icon.Viral-Icon--colorPrimary', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end
  end
end
