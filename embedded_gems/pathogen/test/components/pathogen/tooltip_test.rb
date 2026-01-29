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

      assert_selector 'span#tooltip-123[role="tooltip"]'
      assert_text 'Sample tooltip'
      assert_selector 'span[data-pathogen--tooltip-target="tooltip"]'
    end

    test 'renders with default placement top' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'span[data-placement="top"]'
    end

    %i[bottom left right].each do |placement|
      test "renders with custom placement #{placement}" do
        render_inline(Pathogen::Tooltip.new(
                        text: 'Sample tooltip',
                        id: 'tooltip-123',
                        placement: placement
                      ))

        assert_selector "span[data-placement=\"#{placement}\"]"
      end
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

    test 'renders with Primer-inspired styling and animations' do
      render_inline(Pathogen::Tooltip.new(
                      text: 'Sample tooltip',
                      id: 'tooltip-123'
                    ))

      assert_selector 'span.bg-slate-900.dark\:bg-slate-700.text-white'
      assert_selector 'span.px-3.py-2.text-sm.font-medium.rounded-lg.shadow-sm'
      assert_selector 'span.max-w-xs.inline-block'
      assert_selector 'span.opacity-0.scale-90.invisible'
      assert_selector 'span.transition-all.duration-200.ease-out'
    end

    {
      top: 'origin-bottom', bottom: 'origin-top',
      left: 'origin-right', right: 'origin-left'
    }.each do |placement, origin|
      test "renders with correct origin class for #{placement} placement" do
        render_inline(Pathogen::Tooltip.new(
                        text: 'Sample tooltip',
                        id: 'tooltip-123',
                        placement: placement
                      ))

        assert_selector "span.#{origin}"
      end
    end

    test 'forwards custom attributes via system_arguments' do
      render_inline(
        Pathogen::Tooltip.new(
          text: 'Sample tooltip',
          id: 'tooltip-123',
          class: 'custom-tooltip-class',
          data: { controller: 'custom-controller', action: 'click->custom#action' },
          aria: { label: 'Additional info', live: 'polite' }
        )
      )

      # Custom attributes are applied
      assert_selector 'span#tooltip-123.custom-tooltip-class'
      assert_selector 'span[data-controller="custom-controller"]'
      assert_selector 'span[data-action="click->custom#action"]'
      assert_selector 'span[aria-label="Additional info"]'
      assert_selector 'span[aria-live="polite"]'

      # Required defaults are preserved (role="tooltip" is non-overridable per W3C APG)
      assert_selector 'span[role="tooltip"]'
      assert_selector 'span.bg-slate-900'
      assert_selector 'span[data-pathogen--tooltip-target="tooltip"]'
      assert_selector 'span[data-placement="top"]'
    end
  end
end
