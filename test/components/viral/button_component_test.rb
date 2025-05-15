# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class ButtonComponentTest < ViewComponentTestCase
    # Helper to check for presence of multiple classes on an element
    def assert_classes(element, expected_classes)
      actual_classes = element[:class]&.split || []
      expected_classes.each do |cls|
        assert_includes actual_classes, cls,
                        "Expected element to have class '#{cls}', but had '#{actual_classes.join(' ')}'"
      end
    end

    # 🖼️ Basic Rendering & Content
    # =================================================================================
    test '✅ renders default button with content and base/default state classes' do
      render_inline(Viral::ButtonComponent.new) { 'Click Me!' }
      assert_selector 'button', text: 'Click Me!' do |button_element|
        expected_classes = %w[
          btn btn-default btn-rounded
        ]
        assert_classes(button_element, expected_classes)
      end
    end

    # 🎨 Button States (Default, Primary, Destructive)
    # =================================================================================
    test '🎨 renders primary state with correct classes' do
      render_inline(Viral::ButtonComponent.new(state: :primary)) { 'Primary Action' }
      assert_selector 'button', text: 'Primary Action' do |button_element|
        expected_classes = %w[btn btn-primary btn-rounded]
        assert_classes(button_element, expected_classes)
      end
    end

    test '🎨 renders destructive state with correct classes' do
      render_inline(Viral::ButtonComponent.new(state: :destructive)) { 'Delete Item' }
      assert_selector 'button', text: 'Delete Item' do |button_element|
        expected_classes = %w[btn btn-destructive btn-rounded]
        assert_classes(button_element, expected_classes)
      end
    end

    # 🚫 Disabled States
    # =================================================================================
    test '🚫 renders disabled default button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(disabled: true)) { 'Cannot Click' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Cannot Click' do |button_element|
        expected_classes = %w[btn btn-default btn-rounded]
        assert_classes(button_element, expected_classes)
      end
    end

    test '🚫 renders disabled primary button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(state: :primary, disabled: true)) { 'Processing...' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Processing...' do |button_element|
        expected_classes = %w[btn btn-primary btn-rounded]
        assert_classes(button_element, expected_classes)
      end
    end

    test '🚫 renders disabled destructive button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(state: :destructive, disabled: true)) { 'Deleting...' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Deleting...' do |button_element|
        expected_classes = %w[btn btn-destructive btn-rounded]
        assert_classes(button_element, expected_classes)
      end
    end

    # ↔️ Full Width
    # =================================================================================
    test '↔️ renders full_width button with w-full class' do
      render_inline(Viral::ButtonComponent.new(full_width: true)) { 'Full Width Button' }
      assert_selector 'button', text: 'Full Width Button' do |button_element|
        assert_classes(button_element, %w[w-full])
      end
    end

    #  Disclosure Icons (🔽🔼▶️)
    # =================================================================================
    test '🔽 renders disclosure icon (true defaults to :down)' do
      render_inline(Viral::ButtonComponent.new(disclosure: true)) { 'Open Menu' }
      assert_text 'Open Menu'
      assert_selector "button svg[data-test-selector='caret_down']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🔽 renders disclosure :down icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :down)) { 'Show Details' }
      assert_text 'Show Details'
      assert_selector "button svg[data-test-selector='caret_down']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🔼 renders disclosure :up icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :up)) { 'Hide Details' }
      assert_text 'Hide Details'
      assert_selector "button svg[data-test-selector='caret_up']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '▶️ renders disclosure :right icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :right)) { 'Continue' }
      assert_text 'Continue'
      assert_selector "button svg[data-test-selector='caret_right']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🧐 disclosure :select does not render a specific caret icon via current template' do
      render_inline(Viral::ButtonComponent.new(disclosure: :select)) { 'Select Option' }
      assert_text 'Select Option'
      assert_no_selector "button svg[data-test-selector='caret_down']"
      assert_no_selector "button svg[data-test-selector='caret_up']"
      assert_no_selector "button svg[data-test-selector='caret_right']"
      # NOTE: :select might render a different icon (e.g., 'dots-three')
      # if mapped in IconHelper and ButtonComponent's template
    end

    test '🧐 disclosure :horizontal_dots does not render a specific caret icon via current template' do
      render_inline(Viral::ButtonComponent.new(disclosure: :horizontal_dots)) { 'More Actions' }
      assert_text 'More Actions'
      assert_no_selector "button svg[data-test-selector='caret_down']"
      assert_no_selector "button svg[data-test-selector='caret_up']"
      assert_no_selector "button svg[data-test-selector='caret_right']"
      # NOTE: :horizontal_dots might render a different icon if mapped
    end

    test '💨 renders no disclosure icon when disclosure: false' do
      render_inline(Viral::ButtonComponent.new(disclosure: false)) { 'No Icon Here' }
      assert_text 'No Icon Here'
      assert_no_selector 'button svg'
    end

    test '💨 renders no disclosure icon when disclosure option is not provided' do
      render_inline(Viral::ButtonComponent.new) { 'Still No Icon' }
      assert_text 'Still No Icon'
      assert_no_selector 'button svg'
    end

    # 🏷️ `type` Attribute
    # =================================================================================
    test '🏷️ defaults to type="button"' do
      render_inline(Viral::ButtonComponent.new) { 'Default Type' }
      assert_selector 'button[type="button"]', text: 'Default Type'
    end

    test '🏷️ allows overriding type attribute (e.g., submit)' do
      render_inline(Viral::ButtonComponent.new(type: 'submit')) { 'Submit Form' }
      assert_selector 'button[type="submit"]', text: 'Submit Form'
    end

    test '🏷️ allows setting type to reset' do
      render_inline(Viral::ButtonComponent.new(type: 'reset')) { 'Reset Form' }
      assert_selector 'button[type="reset"]', text: 'Reset Form'
    end

    # ⚙️ Custom HTML Attributes & 🖌️ CSS Classes
    # =================================================================================
    test '⚙️ accepts and renders custom id attribute' do
      render_inline(Viral::ButtonComponent.new(id: 'my-custom-button')) { 'Button with ID' }
      assert_selector 'button#my-custom-button', text: 'Button with ID'
    end

    test '⚙️ accepts and renders custom data attributes' do
      render_inline(Viral::ButtonComponent.new(data: { turbo_confirm: 'Are you sure?' })) { 'Confirm Action' }
      assert_selector 'button[data-turbo-confirm="Are you sure?"]', text: 'Confirm Action'
    end

    test '🖌️ accepts and merges custom CSS classes' do
      custom_class = 'my-extra-class'
      render_inline(Viral::ButtonComponent.new(classes: custom_class)) { 'Styled Button' }
      assert_selector 'button', text: 'Styled Button' do |button_element|
        expected_classes = %w[btn btn-default btn-rounded my-extra-class]
        assert_classes(button_element, expected_classes)
      end
    end

    test '✨ renders combination: primary, full_width, disclosure(:down), custom id & data' do
      render_inline(Viral::ButtonComponent.new(
                      id: 'custom-combo-btn',
                      state: :primary,
                      full_width: true,
                      disclosure: :down,
                      data: { action: 'click->test#action', controller: 'test' }
                    )) { 'Combo Action' }

      assert_selector 'button#custom-combo-btn[data-action="click->test#action"][data-controller="test"]',
                      text: 'Combo Action' do |button_element|
        expected_classes = %w[btn btn-primary btn-rounded w-full]
        assert_classes(button_element, expected_classes)
        assert_selector "svg[data-test-selector='caret_down']"
      end
    end

    # ♿ Accessibility Attributes
    # =================================================================================
    test '♿️ ensures aria-disabled="true" is set for disabled buttons' do
      render_inline(Viral::ButtonComponent.new(disabled: true)) { 'ARIA Disabled' }
      assert_selector 'button[aria-disabled="true"]', text: 'ARIA Disabled'
    end

    test '♿️ ensures no aria-disabled attribute for enabled buttons' do
      render_inline(Viral::ButtonComponent.new) { 'ARIA Enabled' }
      assert_no_selector 'button[aria-disabled="true"]'
      assert_text 'ARIA Enabled'
    end
  end
end
