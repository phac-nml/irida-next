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
        base_style_classes = %w[
          inline-flex items-center justify-center border focus:z-10
          sm:w-auto min-h-11 min-w-11 px-5 py-2.5 rounded-lg
          font-semibold cursor-pointer
        ]
        default_state_classes = %w[
          bg-slate-50 text-slate-900 border-slate-300
          dark:bg-slate-900 dark:text-slate-50 dark:border-slate-700
        ]
        assert_classes(button_element, base_style_classes)
        assert_classes(button_element, default_state_classes)
      end
    end

    # 🎨 Button States (Default, Primary, Destructive)
    # =================================================================================
    test '🎨 renders primary state with correct classes' do
      render_inline(Viral::ButtonComponent.new(state: :primary)) { 'Primary Action' }
      assert_selector 'button', text: 'Primary Action' do |button_element|
        primary_state_classes = %w[
          bg-primary-800 text-white border-primary-800
          dark:bg-primary-700 dark:text-white dark:border-primary-700
        ]
        assert_classes(button_element, primary_state_classes)
        # Ensure default state classes are not present if they conflict
        assert_not_includes button_element[:class]&.split || [], 'bg-slate-50'
      end
    end

    test '🎨 renders destructive state with correct classes' do
      render_inline(Viral::ButtonComponent.new(state: :destructive)) { 'Delete Item' }
      assert_selector 'button', text: 'Delete Item' do |button_element|
        destructive_state_classes = %w[
          bg-red-700 text-white border-red-800
          dark:bg-red-600 dark:text-white dark:border-red-600
        ]
        assert_classes(button_element, destructive_state_classes)
        assert_not_includes button_element[:class]&.split || [], 'bg-slate-50'
      end
    end

    # 🚫 Disabled States
    # =================================================================================
    test '🚫 renders disabled default button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(disabled: true)) { 'Cannot Click' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Cannot Click' do |button_element|
        disabled_default_classes = %w[
          disabled:bg-slate-100 disabled:text-slate-500 disabled:border-slate-200
          disabled:dark:bg-slate-800 disabled:dark:text-slate-400
          disabled:dark:border-slate-700 disabled:cursor-not-allowed
          disabled:opacity-80
        ]
        assert_classes(button_element, disabled_default_classes)
      end
    end

    test '🚫 renders disabled primary button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(state: :primary, disabled: true)) { 'Processing...' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Processing...' do |button_element|
        disabled_primary_classes = %w[
          disabled:bg-primary-100 disabled:text-primary-500 disabled:border-primary-200
          disabled:dark:bg-primary-900 disabled:dark:text-primary-400
          disabled:dark:border-primary-800 disabled:cursor-not-allowed
          disabled:opacity-80
        ]
        assert_classes(button_element, disabled_primary_classes)
      end
    end

    test '🚫 renders disabled destructive button with correct attributes and classes' do
      render_inline(Viral::ButtonComponent.new(state: :destructive, disabled: true)) { 'Deleting...' }
      assert_selector 'button[disabled][aria-disabled="true"]', text: 'Deleting...' do |button_element|
        disabled_destructive_classes = %w[
          disabled:bg-red-100 disabled:text-red-500 disabled:border-red-200
          disabled:dark:bg-red-900 disabled:dark:text-red-400
          disabled:dark:border-red-800 disabled:cursor-not-allowed
          disabled:opacity-80
        ]
        assert_classes(button_element, disabled_destructive_classes)
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
      assert_selector "button span svg[data-test-selector='caret_down']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🔽 renders disclosure :down icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :down)) { 'Show Details' }
      assert_text 'Show Details'
      assert_selector "button span svg[data-test-selector='caret_down']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🔼 renders disclosure :up icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :up)) { 'Hide Details' }
      assert_text 'Hide Details'
      assert_selector "button span svg[data-test-selector='caret_up']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '▶️ renders disclosure :right icon' do
      render_inline(Viral::ButtonComponent.new(disclosure: :right)) { 'Continue' }
      assert_text 'Continue'
      assert_selector "button span svg[data-test-selector='caret_right']" do |svg_element|
        assert_classes(svg_element, %w[size-4 align-middle ml-2])
      end
    end

    test '🧐 disclosure :select does not render a specific caret icon via current template' do
      render_inline(Viral::ButtonComponent.new(disclosure: :select)) { 'Select Option' }
      assert_text 'Select Option'
      assert_no_selector "button span svg[data-test-selector='caret_down']"
      assert_no_selector "button span svg[data-test-selector='caret_up']"
      assert_no_selector "button span svg[data-test-selector='caret_right']"
      # NOTE: :select might render a different icon (e.g., 'dots-three')
      # if mapped in IconHelper and ButtonComponent's template
    end

    test '🧐 disclosure :horizontal_dots does not render a specific caret icon via current template' do
      render_inline(Viral::ButtonComponent.new(disclosure: :horizontal_dots)) { 'More Actions' }
      assert_text 'More Actions'
      assert_no_selector "button span svg[data-test-selector='caret_down']"
      assert_no_selector "button span svg[data-test-selector='caret_up']"
      assert_no_selector "button span svg[data-test-selector='caret_right']"
      # NOTE: :horizontal_dots might render a different icon if mapped
    end

    test '💨 renders no disclosure icon when disclosure: false' do
      render_inline(Viral::ButtonComponent.new(disclosure: false)) { 'No Icon Here' }
      assert_text 'No Icon Here'
      assert_no_selector 'button span svg'
    end

    test '💨 renders no disclosure icon when disclosure option is not provided' do
      render_inline(Viral::ButtonComponent.new) { 'Still No Icon' }
      assert_text 'Still No Icon'
      assert_no_selector 'button span svg'
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
        assert_classes(button_element, [custom_class])
        assert_classes(button_element, %w[bg-slate-50]) # Default state class still present
      end
    end

    # ✨ Combinations
    # =================================================================================
    test '✨ renders combination: primary, full_width, disclosure(:down), custom id & data' do
      render_inline(Viral::ButtonComponent.new(
                      state: :primary,
                      full_width: true,
                      disclosure: :down,
                      id: 'combo-btn',
                      data: { action: 'combo-click' }
                    )) { 'Combo Button!' }

      assert_selector 'button#combo-btn[data-action="combo-click"]', text: 'Combo Button!' do |button_element|
        assert_classes(button_element, %w[bg-primary-800 w-full])
        assert_selector "span svg[data-test-selector='caret_down']"
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
