# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class ButtonTest < ViewComponent::TestCase
    test 'default button' do
      render_inline(Pathogen::Button.new(test_selector: 'playground')) { 'Button' }
      assert_selector 'button[data-test-selector="playground"]:not([disabled])', count: 1, visible: true, text: 'Button'
    end

    test 'default button with disabled' do
      render_inline(Pathogen::Button.new(test_selector: 'playground', disabled: true)) { 'Button' }
      assert_selector 'button[data-test-selector="playground"][disabled]', count: 1, visible: true, text: 'Button'
    end

    test 'button with leading visual icon' do
      component = Pathogen::Button.new(test_selector: 'playground').tap do |c|
        c.with_leading_visual_icon(icon: 'arrow-right')
      end
      render_inline(component) { 'Button' }
      assert_selector(
        'button[data-test-selector="playground"]:not([disabled])',
        count: 1,
        visible: true,
        text: 'Button'
      )
      assert_selector 'button svg.leading_visual_icon', count: 1
    end

    test 'button with trailing visual icon' do
      component = Pathogen::Button.new(test_selector: 'playground').tap do |c|
        c.with_trailing_visual_icon(icon: 'arrow-right')
      end
      render_inline(component) { 'Button' }
      assert_selector(
        'button[data-test-selector="playground"]:not([disabled])',
        count: 1,
        visible: true,
        text: 'Button'
      )
      assert_selector 'button svg.trailing_visual_icon', count: 1
    end

    test 'button with custom class' do
      render_inline(Pathogen::Button.new(test_selector: 'playground', class: 'custom-class')) { 'Button' }
      assert_selector 'button.custom-class[data-test-selector="playground"]', count: 1, visible: true, text: 'Button'
    end

    test 'button with aria attributes' do
      render_inline(
        Pathogen::Button.new(
          test_selector: 'playground',
          aria: { label: 'Custom Label', expanded: true }
        )
      ) { 'Button' }
      assert_selector(
        'button[data-test-selector="playground"][aria-label="Custom Label"][aria-expanded="true"]',
        count: 1,
        visible: true,
        text: 'Button'
      )
    end

    test 'button as a link' do
      render_inline(Pathogen::Button.new(test_selector: 'playground', tag: :a, href: '/example')) { 'Link Button' }
      assert_selector 'a[data-test-selector="playground"][href="/example"]', count: 1, visible: true,
                                                                             text: 'Link Button'
    end
  end
end
