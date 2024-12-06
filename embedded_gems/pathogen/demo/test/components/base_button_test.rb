# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test for the BaseButton component
  class BaseButtonTest < ViewComponent::TestCase
    def test_renders_default_button
      render_inline(Pathogen::BaseButton.new) { 'Click me' }

      assert_selector "button[type='button']", text: 'Click me'
    end

    def test_renders_anchor_tag
      render_inline(Pathogen::BaseButton.new(tag: :a)) { 'Click me' }

      assert_selector 'a', text: 'Click me'
      refute_selector 'a[type]' # Ensure type is not set on anchor tags
    end

    def test_renders_submit_button
      render_inline(Pathogen::BaseButton.new(type: :submit)) { 'Submit' }

      assert_selector "button[type='submit']", text: 'Submit'
    end

    def test_renders_reset_button
      render_inline(Pathogen::BaseButton.new(type: :reset)) { 'Reset' }

      assert_selector "button[type='reset']", text: 'Reset'
    end

    def test_handles_disabled_state
      render_inline(Pathogen::BaseButton.new(disabled: true)) { 'Disabled' }

      assert_selector 'button[disabled]', text: 'Disabled'
    end

    def test_converts_disabled_anchor_to_button
      render_inline(Pathogen::BaseButton.new(tag: :a, disabled: true)) { 'Disabled Link' }

      assert_selector 'button[disabled]', text: 'Disabled Link'
      refute_selector 'a' # Ensure it's not an anchor
    end

    test 'raises error if passed incorrect tag' do
      assert_raises Pathogen::FetchOrFallbackHelper::InvalidValueError do
        render_inline Pathogen::BaseButton.new(tag: :invalid)
      end
    end

    test 'raises error if passed incorrect type' do
      assert_raises Pathogen::FetchOrFallbackHelper::InvalidValueError do
        render_inline Pathogen::BaseButton.new(type: :invalid)
      end
    end
  end
end
