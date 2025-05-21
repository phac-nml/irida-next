# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class AvatarComponentTest < ViewComponentTestCase
    test 'default avatar' do
      render_inline(Viral::AvatarComponent.new(name: 'J'))
      assert_selector('span.avatar')
      assert_selector('span.w-12.h-12')
      assert_text('J')
    end

    test 'small avatar' do
      render_inline(Viral::AvatarComponent.new(name: 'J', size: :small))
      assert_selector('span.avatar')
      assert_selector('span.w-8.h-8')
      assert_text('J')
    end

    test 'large avatar' do
      render_inline(Viral::AvatarComponent.new(name: 'J', size: :large))
      assert_selector('span.avatar')
      assert_selector('span.w-16.h-16')
      assert_text('J')
    end

    test 'with link' do
      render_inline(Viral::AvatarComponent.new(name: 'J', url: 'https://example.com'))
      assert_selector('a[href="https://example.com"]')
      assert_selector('a.avatar')
    end
  end
end
