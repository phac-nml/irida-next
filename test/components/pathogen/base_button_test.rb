# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class BaseButtonTest < ViewComponent::TestCase
    test 'renders button with default type and classes' do
      render_inline(BaseButton.new) { 'Click me' }

      assert_selector "button[type='button']", text: 'Click me'
      assert_selector '.inline-flex.items-center.justify-center', count: 1
      assert_selector '.px-5.py-2\.5.text-sm.font-semibold', count: 1
      assert_selector '.rounded-lg', count: 1
      assert_selector '.disabled\:cursor-not-allowed', count: 1
    end

    test 'renders anchor tag when specified' do
      render_inline(BaseButton.new(tag: :a, href: '#')) { 'Link' }

      assert_selector 'a[href="#"]', text: 'Link'
      refute_selector 'a[type]' # Type should not be set on anchor tags
    end

    test 'renders submit and reset button types' do
      render_inline(BaseButton.new(type: :submit)) { 'Submit' }
      assert_selector "button[type='submit']", text: 'Submit'

      render_inline(BaseButton.new(type: :reset)) { 'Reset' }
      assert_selector "button[type='reset']", text: 'Reset'
    end

    test 'applies disabled state with proper attributes' do
      render_inline(BaseButton.new(disabled: true)) { 'Disabled' }

      assert_selector 'button[disabled]', text: 'Disabled'
      assert_selector '[aria_disabled="true"]', text: 'Disabled'
      assert_selector '.disabled\:cursor-not-allowed', text: 'Disabled'
      assert_selector 'button[tabindex="-1"]', text: 'Disabled'
    end

    test 'converts disabled anchor to button with proper attributes' do
      render_inline(BaseButton.new(tag: :a, disabled: true)) { 'Disabled Link' }

      assert_selector 'button[disabled]', text: 'Disabled Link'
      assert_selector '[aria_disabled="true"]', text: 'Disabled Link'
      refute_selector 'a' # Should be converted to button
      assert_selector 'button[tabindex="-1"]', text: 'Disabled Link'
    end

    test 'preserves custom classes' do
      render_inline(BaseButton.new(classes: 'custom-class another-class')) { 'Custom' }

      assert_selector 'button.custom-class.another-class', text: 'Custom'
    end

    test 'includes cursor-pointer class by default' do
      render_inline(BaseButton.new) { 'Clickable' }

      assert_selector 'button.cursor-pointer', text: 'Clickable'
    end

    test 'sets tabindex to -1 when disabled' do
      render_inline(BaseButton.new(disabled: true)) { 'Disabled' }

      assert_selector 'button[tabindex="-1"]', text: 'Disabled'
    end

    test 'raises error for invalid tag' do
      assert_raises ArgumentError do
        render_inline Pathogen::BaseButton.new(tag: :invalid)
      end
    end

    test 'raises error for invalid type' do
      assert_raises ArgumentError do
        render_inline Pathogen::BaseButton.new(type: :invalid)
      end
    end
  end
end
