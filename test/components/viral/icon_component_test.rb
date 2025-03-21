# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class IconComponentTest < ViewComponentTestCase
    test 'default' do
      render_inline(Viral::IconComponent.new(name: 'home'))
      assert_selector 'svg.viral-icon__Svg', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with custom class' do
      render_inline(Viral::IconComponent.new(name: 'home', classes: 'w-8 h-8'))
      assert_selector 'span.viral-icon.w-8.h-8', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with subdued color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :subdued))
      assert_selector 'span.viral-icon.viral-icon--colorSubdued', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with critical color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :critical))
      assert_selector 'span.viral-icon.viral-icon--colorCritical', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with warning color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :warning))
      assert_selector 'span.viral-icon.viral-icon--colorWarning', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with success color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :success))
      assert_selector 'span.viral-icon.viral-icon--colorSuccess', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with primary color' do
      render_inline(Viral::IconComponent.new(name: 'home', color: :primary))
      assert_selector 'span.viral-icon.viral-icon--colorPrimary', count: 1
      assert_selector 'svg[focusable="false"]', count: 1
    end

    test 'with custom with custom content' do
      render_inline(Viral::IconComponent.new(color: :primary)) do
        'ANY CONTENT'
      end
      assert_selector 'span.viral-icon.viral-icon--colorPrimary', count: 1
      assert_text 'ANY CONTENT'
    end
  end
end
