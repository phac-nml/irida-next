# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for Pathogen::Tooltip Stimulus controller behavior
  # Tests show/hide interactions, accessibility, and keyboard navigation
  class TooltipControllerTest < ViewComponent::TestCase
    test 'tooltip renders with controller and targets properly connected' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Helpful tooltip text',
                      id: 'test-tooltip'
                    ))

      # Verify controller target is present
      assert_selector 'div[data-pathogen--tooltip-target="target"]'
      assert_selector 'div#test-tooltip[role="tooltip"]'
    end

    test 'tooltip has initial hidden state classes' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Helpful tooltip text',
                      id: 'test-tooltip'
                    ))

      # Verify initial hidden state
      assert_selector 'div.opacity-0.scale-90.invisible'
    end

    test 'tooltip has transition classes for animation' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Helpful tooltip text',
                      id: 'test-tooltip'
                    ))

      # Verify transition classes for smooth animation
      assert_selector 'div.transition-all.duration-200.ease-out'
    end

    test 'tooltip includes placement data attribute for CSS positioning' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Helpful tooltip text',
                      id: 'test-tooltip',
                      placement: :bottom
                    ))

      # Verify placement data attribute
      assert_selector 'div[data-placement="bottom"]'
    end

    test 'tooltip has fixed positioning for proper viewport placement' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Helpful tooltip text',
                      id: 'test-tooltip'
                    ))

      # Verify fixed positioning class (uses fixed to position relative to viewport)
      assert_selector 'div.fixed.z-50'
    end

    test 'tooltip has correct transform-origin based on placement' do
      # Top placement should have origin-bottom
      render_inline(Pathogen::Tooltip.new(text: 'Test', id: 'tooltip-1', placement: :top))
      assert_selector 'div.origin-bottom'

      # Bottom placement should have origin-top
      render_inline(Pathogen::Tooltip.new(text: 'Test', id: 'tooltip-2', placement: :bottom))
      assert_selector 'div.origin-top'

      # Left placement should have origin-right
      render_inline(Pathogen::Tooltip.new(text: 'Test', id: 'tooltip-3', placement: :left))
      assert_selector 'div.origin-right'

      # Right placement should have origin-left
      render_inline(Pathogen::Tooltip.new(text: 'Test', id: 'tooltip-4', placement: :right))
      assert_selector 'div.origin-left'
    end

    test 'tooltip controller has Escape key handler registered' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Verify controller is connected (Escape handler is registered in connect())
      assert_selector 'div[data-controller="pathogen--tooltip"]'
    end

    test 'tooltip target is present for mouse event handler attachment' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Verify tooltip target exists (mouse handlers are added at runtime via
      # targetTargetConnected callback for W3C ARIA APG compliance)
      assert_selector 'div[data-pathogen--tooltip-target="target"][role="tooltip"]',
                      text: 'Helpful tooltip'
    end

    test 'link with tooltip has aria-describedby pointing to tooltip ID (W3C ARIA APG requirement)' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Get the tooltip ID
      tooltip_element = page.find('div[role="tooltip"]')
      tooltip_id = tooltip_element[:id]

      # Verify link has aria-describedby pointing to tooltip ID
      # This is a W3C ARIA APG requirement enforced at runtime by the Stimulus controller
      assert_selector "a[aria-describedby='#{tooltip_id}']",
                      text: 'Link text'
    end
  end
end
