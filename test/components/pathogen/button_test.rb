# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class ButtonTest < ViewComponent::TestCase
    # Basic Button Tests
    test 'renders default button' do
      render_inline(Pathogen::Button.new(test_selector: 'default-button')) { 'Click me' }
      assert_selector 'button[data-test-selector="default-button"]', 
                     text: 'Click me',
                     class: 'border-slate-300 bg-slate-50 text-slate-900',
                     count: 1
    end

    test 'renders disabled button' do
      render_inline(Pathogen::Button.new(test_selector: 'disabled-button', disabled: true)) { 'Disabled' }
      assert_selector 'button[data-test-selector="disabled-button"][disabled]', 
                     text: 'Disabled',
                     class: 'disabled:border-slate-200 disabled:bg-slate-100 disabled:text-slate-500',
                     count: 1
    end

    test 'renders block button' do
      render_inline(Pathogen::Button.new(test_selector: 'block-button', block: true)) { 'Block Button' }
      assert_selector 'button.block[data-test-selector="block-button"]', 
                     text: 'Block Button',
                     class: 'w-full',
                     count: 1
    end

    test 'merges custom classes' do
      render_inline(Pathogen::Button.new(test_selector: 'custom-class', class: 'custom-class')) { 'Custom' }
      assert_selector 'button.custom-class[data-test-selector="custom-class"]', 
                     text: 'Custom',
                     count: 1
    end

    test 'renders with aria attributes' do
      render_inline(Pathogen::Button.new(
        test_selector: 'aria-button',
        aria: { label: 'Custom Label', expanded: 'false' }
      )) { 'Aria' }
      
      assert_selector 'button[data-test-selector="aria-button"][aria-label="Custom Label"][aria-expanded="false"]', 
                     text: 'Aria',
                     count: 1
    end

    # Visual Elements Tests
    test 'renders with leading icon' do
      component = Pathogen::Button.new(test_selector: 'leading-icon').tap do |c|
        c.with_leading_visual_icon(icon: 'plus')
      end
      render_inline(component) { 'Add' }
      
      assert_selector 'button[data-test-selector="leading-icon"]', text: 'Add', count: 1
      assert_selector 'button svg.leading_visual_icon', count: 1
      assert_selector 'button .leading_visual_icon.w-4.h-4', count: 1
    end

    test 'renders with trailing icon' do
      component = Pathogen::Button.new(test_selector: 'trailing-icon').tap do |c|
        c.with_trailing_visual_icon(icon: 'chevron-right')
      end
      render_inline(component) { 'Next' }
      
      assert_selector 'button[data-test-selector="trailing-icon"]', text: 'Next', count: 1
      assert_selector 'button svg.trailing_visual_icon', count: 1
      assert_selector 'button .trailing_visual_icon.w-4.h-4', count: 1
    end

    test 'renders with custom SVG' do
      component = Pathogen::Button.new(test_selector: 'custom-svg').tap do |c|
        c.with_leading_visual_svg do
          '<path d="M10 5a1 1 0 0 1 1 1v3h3a1 1 0 1 1 0 2h-3v3a1 1 0 1 1-2 0v-3H6a1 1 0 1 1 0-2h3V6a1 1 0 0 1 1-1z"/>'.html_safe
        end
      end
      render_inline(component) { 'Custom SVG' }
      
      assert_selector 'button[data-test-selector="custom-svg"]', text: 'Custom SVG', count: 1
      assert_selector 'button svg.leading_visual_svg', count: 1
    end

    # Color Scheme Tests
    test 'renders primary scheme' do
      render_inline(Pathogen::Button.new(test_selector: 'primary-button', scheme: :primary)) { 'Primary' }
      button = page.find('button[data-test-selector="primary-button"]')
      assert_match /Primary/, button.text.squish
      assert_match /bg-primary-800/, button['class']
      assert_match /text-white/, button['class']
    end

    test 'renders danger scheme' do
      render_inline(Pathogen::Button.new(test_selector: 'danger-button', scheme: :danger)) { 'Danger' }
      button = page.find('button[data-test-selector="danger-button"]')
      assert_match /Danger/, button.text.squish
      assert_match /bg-red-700/, button['class']
      assert_match /text-white/, button['class']
    end

    test 'renders default scheme when invalid' do
      assert_raises Pathogen::FetchOrFallbackHelper::InvalidValueError do
        render_inline(Pathogen::Button.new(test_selector: 'invalid-scheme', scheme: :invalid)) { 'Default' }
      end
    end

    test 'falls back to default scheme in production when invalid' do
      # Test the behavior by stubbing the fetch_or_fallback method directly
      original_method = Pathogen::Button.instance_method(:fetch_or_fallback)
      
      # Define a new implementation that returns the default value
      Pathogen::Button.define_method(:fetch_or_fallback) do |*_args|
        :default
      end
      
      render_inline(Pathogen::Button.new(test_selector: 'invalid-scheme', scheme: :invalid)) { 'Default' }
      button = page.find('button[data-test-selector="invalid-scheme"]')
      assert_match /Default/, button.text.squish
      assert_match /bg-slate-50/, button['class']
      assert_match /text-slate-900/, button['class']
    ensure
      # Restore the original method
      Pathogen::Button.define_method(:fetch_or_fallback, original_method)
    end

    # Edge Cases
    test 'renders empty content' do
      render_inline(Pathogen::Button.new(test_selector: 'empty-button'))
      assert_selector 'button[data-test-selector="empty-button"]', 
                     text: '',
                     count: 1
    end

    test 'renders as link when tag is :a' do
      render_inline(Pathogen::Button.new(
        test_selector: 'link-button',
        tag: :a,
        href: '/example'
      )) { 'Link' }
      
      assert_selector 'a[data-test-selector="link-button"][href="/example"]', 
                     text: 'Link',
                     count: 1
    end
  end
end
