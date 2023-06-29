# frozen_string_literal: true

require 'test_helper'

module Viral
  class AvatarComponentTest < ViewComponent::TestCase
    test 'default avatar' do
      render_inline(Viral::AvatarComponent.new(initials: 'J'))
      assert_selector('div.avatar')
      assert_selector('div.w-12.h-12')
      assert_text('J')
    end

    test 'small avatar' do
      render_inline(Viral::AvatarComponent.new(initials: 'J', size: :small))
      assert_selector('div.avatar')
      assert_selector('div.w-8.h-8')
      assert_text('J')
    end

    test 'large avatar' do
      render_inline(Viral::AvatarComponent.new(initials: 'J', size: :large))
      assert_selector('div.avatar')
      assert_selector('div.w-16.h-16')
      assert_text('J')
    end
  end
end
