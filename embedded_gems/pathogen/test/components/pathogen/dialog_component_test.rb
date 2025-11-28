# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for Pathogen::DialogComponent
  # Validates W3C/ARIA compliance, slot-based API, and accessibility features
  # rubocop:disable Metrics/ClassLength
  class DialogComponentTest < ViewComponent::TestCase
    # Task Group 1: Component Foundation Layer Tests

    test 'renders with default size and dismissible mode' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { 'Title' }
        dialog.with_body { 'Content' }
      end

      # Controller should be on the wrapper
      assert_selector 'div[data-controller="pathogen--dialog"]'
      assert_selector 'div[data-pathogen--dialog-dismissible-value="true"]'
      # Backdrop target should be on inner container
      assert_selector 'div[data-pathogen--dialog-target="backdrop"]'
      # Dialog element should have proper ARIA
      assert_selector 'div[role="dialog"]'
      assert_selector 'div[aria-modal="true"]'
    end

    test 'applies correct size classes for all variants' do
      size_mappings = {
        small: 'max-w-md',
        medium: 'max-w-2xl',
        large: 'max-w-4xl',
        xlarge: 'max-w-6xl'
      }

      size_mappings.each do |size, expected_class|
        render_inline(Pathogen::DialogComponent.new(size: size)) do |dialog|
          dialog.with_body { 'Content' }
        end

        assert_selector "div[role='dialog'].#{expected_class}"
      end
    end

    test 'sets non-dismissible mode attributes correctly' do
      render_inline(Pathogen::DialogComponent.new(dismissible: false)) do |dialog|
        dialog.with_header { 'Title' }
        dialog.with_body { 'Content' }
      end

      # Controller dismissible value on wrapper
      assert_selector 'div[data-pathogen--dialog-dismissible-value="false"]'
      # ESC handler on the dialog element itself
      assert_selector 'div[role="dialog"][data-action="keydown.esc->pathogen--dialog#handleEsc"]'
    end

    test 'renders all three slots when provided' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { 'Header Content' }
        dialog.with_body { 'Body Content' }
        dialog.with_footer { 'Footer Content' }
      end

      assert_text 'Header Content'
      assert_text 'Body Content'
      assert_text 'Footer Content'
    end

    test 'does not render footer when not provided' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { 'Header' }
        dialog.with_body { 'Body' }
      end

      assert_text 'Header'
      assert_text 'Body'
      # Footer container should not be present
      assert_no_selector '[data-dialog-footer]'
    end

    test 'generates unique ID for each instance' do
      component1 = Pathogen::DialogComponent.new
      component2 = Pathogen::DialogComponent.new

      assert_not_equal component1.id, component2.id
      assert_match(/dialog-component-/, component1.id)
      assert_match(/dialog-component-/, component2.id)
    end

    test 'uses medium size as default' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_selector 'div[role="dialog"].max-w-2xl'
    end

    test 'raises error for invalid size option in test environment' do
      error = assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
        Pathogen::DialogComponent.new(size: :invalid)
      end

      assert_match(/Expected one of: \[:small, :medium, :large, :xlarge\]/, error.message)
      assert_match(/Got: :invalid/, error.message)
    end

    # Task Group 2: Template and Styling Layer Tests

    test 'renders close button for dismissible dialogs' do
      render_inline(Pathogen::DialogComponent.new(dismissible: true)) do |dialog|
        dialog.with_header { 'Title' }
        dialog.with_body { 'Content' }
      end

      assert_selector 'button[data-action="click->pathogen--dialog#close"]'
      assert_selector 'button[data-pathogen--dialog-target="closeButton"]'
    end

    test 'does not render close button for non-dismissible dialogs' do
      render_inline(Pathogen::DialogComponent.new(dismissible: false)) do |dialog|
        dialog.with_header { 'Title' }
        dialog.with_body { 'Content' }
      end

      assert_no_selector 'button[data-action="click->pathogen--dialog#close"]'
      assert_no_selector 'button[data-pathogen--dialog-target="closeButton"]'
    end

    test 'renders scroll shadow elements' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_selector '[data-pathogen--dialog-target="topShadow"]'
      assert_selector '[data-pathogen--dialog-target="bottomShadow"]'
    end

    test 'body section has scroll event handler' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_selector(
        '[data-pathogen--dialog-target="body"]' \
        '[data-action="scroll->pathogen--dialog#updateScrollShadows"]'
      )
    end

    test 'renders backdrop with click handler for dismissible dialogs' do
      render_inline(Pathogen::DialogComponent.new(dismissible: true)) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_selector '[data-action="click->pathogen--dialog#closeOnBackdrop"]'
    end

    test 'renders backdrop without click handler for non-dismissible dialogs' do
      render_inline(Pathogen::DialogComponent.new(dismissible: false)) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_no_selector '[data-action="click->pathogen--dialog#closeOnBackdrop"]'
    end

    test 'header has correct aria-labelledby reference' do
      component = Pathogen::DialogComponent.new
      render_inline(component) do |dialog|
        dialog.with_header { 'My Title' }
        dialog.with_body { 'Content' }
      end

      assert_selector "div[role='dialog'][aria-labelledby='#{component.id}-title']"
      assert_selector "##{component.id}-title", text: 'My Title'
    end

    test 'applies dark mode styling classes' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_body { 'Content' }
      end

      assert_selector 'div[role="dialog"].bg-white.dark\\:bg-slate-800'
    end

    # Task Group 3: Show Button Slot Tests

    test 'renders show_button slot with correct Stimulus action' do
      component = Pathogen::DialogComponent.new
      render_inline(component) do |dialog|
        dialog.with_show_button { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      assert_selector 'button[data-action="click->pathogen--dialog#open"]', text: 'Open Dialog'
    end

    test 'show_button has correct ID format' do
      component = Pathogen::DialogComponent.new
      render_inline(component) do |dialog|
        dialog.with_show_button { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      assert_selector "button#dialog-show-#{component.id}"
    end

    test 'show_button accepts scheme parameter' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_show_button(scheme: :primary) { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      # Primary scheme button should have primary background
      assert_selector 'button.bg-primary-700', text: 'Open Dialog'
    end

    test 'show_button accepts size parameter' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_show_button(size: :small) { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      # Small size button should have appropriate text size
      assert_selector 'button.text-xs', text: 'Open Dialog'
    end

    test 'show_button accepts block parameter for full width' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_show_button(block: true) { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      assert_selector 'button.block.w-full', text: 'Open Dialog'
    end

    test 'dialog can be rendered without show_button slot' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { 'Title' }
        dialog.with_body { 'Content' }
      end

      assert_selector 'div[role="dialog"]'
      assert_no_selector 'button[data-action="click->pathogen--dialog#open"]'
    end

    test 'show_button accepts additional system arguments' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_show_button(class: 'custom-class', aria: { label: 'Open custom dialog' }) do
          'Open Dialog'
        end
        dialog.with_body { 'Content' }
      end

      assert_selector 'button.custom-class[aria-label="Open custom dialog"]'
    end

    test 'dialog accepts custom ID and show_button uses it for button ID' do
      render_inline(Pathogen::DialogComponent.new(id: 'my-custom-dialog')) do |dialog|
        dialog.with_show_button { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      assert_selector 'button#dialog-show-my-custom-dialog'
      assert_selector 'button[data-action="click->pathogen--dialog#open"]'
      assert_selector 'div[role="dialog"]#my-custom-dialog'
    end

    test 'show_button appends dialog action to existing actions' do
      render_inline(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_show_button(data: { action: 'custom#action' }) { 'Open Dialog' }
        dialog.with_body { 'Content' }
      end

      # Both actions should be present in the correct order
      assert_selector 'button[data-action="custom#action click->pathogen--dialog#open"]', text: 'Open Dialog'
    end
  end
  # rubocop:enable Metrics/ClassLength
end
