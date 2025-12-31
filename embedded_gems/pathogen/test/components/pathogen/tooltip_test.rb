# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for Pathogen::Tooltip component
  # Validates placement parameter, ID generation, ARIA attributes, and rendering
  class TooltipTest < ViewComponent::TestCase
    test 'renders with required parameters' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'div#tooltip-123[role="tooltip"]'
      assert_text 'Sample tooltip'
      assert_selector 'div[data-pathogen--tooltip-target="target"]'
    end

    test 'renders with default placement top' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'div[data-placement="top"]'
    end

    test 'renders with custom placement bottom' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :bottom
                    ))

      assert_selector 'div[data-placement="bottom"]'
    end

    test 'renders with custom placement left' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :left
                    ))

      assert_selector 'div[data-placement="left"]'
    end

    test 'renders with custom placement right' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :right
                    ))

      assert_selector 'div[data-placement="right"]'
    end

    test 'raises error for invalid placement value' do
      error = assert_raises(ArgumentError) do
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          placement: :invalid
        )
      end
      assert_equal 'placement must be one of: :top, :bottom, :left, :right', error.message
    end

    test 'renders with Primer-inspired styling' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'div.bg-slate-900.dark\:bg-slate-700.text-white'
      assert_selector 'div.px-3.py-2.text-sm.font-medium.rounded-lg.shadow-sm'
      assert_selector 'div.max-w-xs.inline-block'
    end

    test 'renders with animation classes' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'div.opacity-0.scale-90.invisible'
      assert_selector 'div.transition-all.duration-200.ease-out'
    end

    test 'renders with correct origin class for top placement' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :top
                    ))

      assert_selector 'div.origin-bottom'
    end

    test 'renders with correct origin class for bottom placement' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :bottom
                    ))

      assert_selector 'div.origin-top'
    end

    test 'renders with correct origin class for left placement' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :left
                    ))

      assert_selector 'div.origin-right'
    end

    test 'renders with correct origin class for right placement' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123',
                      placement: :right
                    ))

      assert_selector 'div.origin-left'
    end

    test 'forwards custom classes via system_arguments' do
      render_inline(
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          class: 'custom-tooltip-class'
        )
      )

      assert_selector 'div#tooltip-123.custom-tooltip-class'
      # Should still have base classes
      assert_selector 'div.bg-slate-900'
    end

    test 'forwards custom data attributes via system_arguments' do
      render_inline(
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          data: {
            controller: 'custom-controller',
            action: 'click->custom#action'
          }
        )
      )

      assert_selector 'div[data-controller="custom-controller"]'
      assert_selector 'div[data-action="click->custom#action"]'
      # Should still have required data attributes
      assert_selector 'div[data-pathogen--tooltip-target="target"]'
      assert_selector 'div[data-placement="top"]'
    end

    test 'forwards custom ARIA attributes via system_arguments' do
      render_inline(
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          aria: {
            label: 'Additional info',
            live: 'polite'
          }
        )
      )

      assert_selector 'div[aria-label="Additional info"]'
      assert_selector 'div[aria-live="polite"]'
      # Should still have role attribute
      assert_selector 'div[role="tooltip"]'
    end

    test 'allows overriding role via system_arguments' do
      render_inline(
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          role: 'status'
        )
      )

      assert_selector 'div[role="status"]'
    end
  end
end
