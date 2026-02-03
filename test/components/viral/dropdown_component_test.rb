# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class DropdownComponentTest < ViewComponentTestCase
    test 'renders dropdown with label and icon' do
      render_inline(Viral::DropdownComponent.new(label: 'Menu', icon: :dots)) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      assert_selector('button', text: 'Menu')
      # When label is present, aria-label is not added
      assert_no_selector('button[aria-label]')
    end

    test 'deep merges data attributes from system_arguments' do
      render_inline(
        Viral::DropdownComponent.new(
          icon: :dots,
          aria: { label: 'Custom Menu' },
          system_arguments: {
            data: { 'custom-target': 'trigger', 'custom-action': 'click' }
          }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      button = page.find('button[aria-label="Custom Menu"]')

      # Should have viral--dropdown-target (base)
      assert_equal 'trigger', button['data-viral--dropdown-target'],
                   'Should preserve viral--dropdown-target from base args'

      # Should have custom data attributes
      assert_equal 'trigger', button['data-custom-target'],
                   'Should merge custom data-target attribute'
      assert_equal 'click', button['data-custom-action'],
                   'Should merge custom data-action attribute'
    end

    test 'deep merges aria attributes from system_arguments' do
      render_inline(
        Viral::DropdownComponent.new(
          icon: :dots,
          aria: { label: 'Custom Menu' },
          system_arguments: {
            aria: { describedby: 'tooltip-1' }
          }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      button = page.find('button[aria-label="Custom Menu"]')

      # Should have aria-expanded (base)
      assert_equal 'false', button['aria-expanded'],
                   'Should preserve aria-expanded from base args'

      # Should have aria-haspopup (base)
      assert_equal 'true', button['aria-haspopup'],
                   'Should preserve aria-haspopup from base args'

      # Should have custom aria-describedby
      assert_equal 'tooltip-1', button['aria-describedby'],
                   'Should merge custom aria-describedby attribute'
    end

    test 'preserves both viral--dropdown and custom stimulus targets' do
      render_inline(
        Viral::DropdownComponent.new(
          icon: :dots,
          aria: { label: 'Test Menu' },
          system_arguments: {
            data: { 'pathogen--tooltip-target': 'trigger' }
          }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      button = page.find('button[aria-label="Test Menu"]')

      # Should have both targets
      assert_equal 'trigger', button['data-viral--dropdown-target'],
                   'Should preserve viral--dropdown-target'
      assert_equal 'trigger', button['data-pathogen--tooltip-target'],
                   'Should preserve pathogen--tooltip-target'
    end

    test 'merges other system arguments' do
      render_inline(
        Viral::DropdownComponent.new(
          icon: :dots,
          aria: { label: 'Test Menu' },
          system_arguments: {
            id: 'custom-id',
            class: 'custom-class'
          }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      # Custom ID should override base ID (shallow merge behavior)
      assert_selector('button#custom-id')
    end

    test 'renders dropdown items' do
      render_inline(Viral::DropdownComponent.new(label: 'Menu')) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '/path1')
        dropdown.with_item(label: 'Item 2', url: '/path2')
      end

      # Items are rendered but may be hidden by default
      assert_selector('a[href="/path1"]', text: 'Item 1', visible: :all)
      assert_selector('a[href="/path2"]', text: 'Item 2', visible: :all)
    end

    test 'renders with icon only and aria-label' do
      render_inline(
        Viral::DropdownComponent.new(
          icon: :dots,
          aria: { label: 'Actions' }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      assert_selector('button[aria-label="Actions"]')
      assert_no_selector('button', text: 'Actions') # No visible label
    end

    test 'raises error for icon-only button without aria-label' do
      assert_raises(ArgumentError, match: /Icon-only buttons must have an aria-label/) do
        render_inline(Viral::DropdownComponent.new(icon: :dots)) do |dropdown|
          dropdown.with_item(label: 'Item 1', url: '#')
        end
      end
    end

    test 'renders accessible tooltip when tooltip text is provided' do
      render_inline(
        Viral::DropdownComponent.new(
          label: 'Menu',
          tooltip: 'Helpful dropdown tooltip'
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      container = page.find('div[data-controller*="pathogen--tooltip"]', match: :first)
      button = container.find('button')
      tooltip = container.find('div[role="tooltip"]', text: 'Helpful dropdown tooltip', visible: :all)

      assert_equal 'trigger', button['data-pathogen--tooltip-target']
      assert_equal tooltip[:id], button['aria-describedby']
    end

    test 'appends tooltip id to existing aria-describedby' do
      render_inline(
        Viral::DropdownComponent.new(
          label: 'Menu',
          tooltip: 'Helpful dropdown tooltip',
          system_arguments: { aria: { describedby: 'existing-id' } }
        )
      ) do |dropdown|
        dropdown.with_item(label: 'Item 1', url: '#')
      end

      button = page.find('button', text: 'Menu')
      describedby = button['aria-describedby']

      assert_includes describedby.split, 'existing-id'
      assert describedby.split.size >= 2, 'tooltip id should be appended to existing describedby'
    end
  end
end
