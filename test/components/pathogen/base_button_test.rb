# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class BaseButtonTest < ViewComponent::TestCase
    test 'renders a button' do
      render_inline Pathogen::BaseButton.new

      assert_selector 'button[type="button"]'
      assert_no_selector 'a'
      assert_no_selector 'button[disabled]'
    end

    test 'renders a disabled button' do
      render_inline Pathogen::BaseButton.new(disabled: true)

      assert_selector 'button[disabled]'
    end

    test 'renders a link' do
      render_inline Pathogen::BaseButton.new(tag: :a, href: 'https://example.com')

      assert_selector 'a[href="https://example.com"]'
    end

    test 'renders a disabled button if a tag is used' do
      render_inline Pathogen::BaseButton.new(tag: :a, href: 'https://example.com', disabled: true)

      assert_selector 'button[disabled]'
    end

    test 'renders a button with type reset' do
      render_inline Pathogen::BaseButton.new(type: :reset)

      assert_selector 'button[type="reset"]'
    end
  end
end
