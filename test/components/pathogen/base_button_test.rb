# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class BaseButtonTest < ViewComponent::TestCase
    test 'renders a button' do
      render_inline Pathogen::BaseButton.new

      assert_selector 'button[type="button"]'
      assert_no_selector 'button[disabled]'
      assert_no_selector 'button[data-test-selector]'
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

    test 'render a button with custom classes' do
      render_inline Pathogen::BaseButton.new(classes: 'text-orange-500')

      assert_selector 'button.text-orange-500'
    end

    test 'renders button with test selector' do
      render_inline Pathogen::BaseButton.new(test_selector: 'test-selector')

      assert_selector '[data-test-selector="test-selector"]'
    end

    test 'raises error if passed incorrect tag' do
      assert_raises Pathogen::FetchOrFallbackHelper::InvalidValueError do
        render_inline Pathogen::BaseButton.new(tag: :div)
      end
    end

    test 'raises error if passed incorrect type' do
      assert_raises Pathogen::FetchOrFallbackHelper::InvalidValueError do
        render_inline Pathogen::BaseButton.new(type: :invalid)
      end
    end
  end
end
