# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component default rendering' do
      visit('/rails/view_components/viral_dropdown_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_text 'Organism'
        assert_no_selector 'svg.icon-chevron_down' # No caret by default
        assert_no_selector '.viral-dropdown--icon' # No icon by default

        click_on 'Organism'
        assert_text 'Aspergillus awamori'
        assert_text 'Bacillus cereus'
        assert_text 'Pseudomonas aeruginosa'
      end
    end

    test 'dropdown component with label and caret' do
      visit('/rails/view_components/viral_dropdown_component/with_caret')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_text 'Organism'
        assert_selector 'svg.icon-chevron_down' # Assert caret is present
        assert_no_text 'Aspergillus awamori'
        assert_no_text 'Bacillus cereus'
        assert_no_text 'Pseudomonas aeruginosa'

        click_on 'Organism'
        assert_text 'Aspergillus awamori'
        assert_text 'Bacillus cereus'
        assert_text 'Pseudomonas aeruginosa'
      end
    end

    test 'dropdown component with icon' do
      visit('/rails/view_components/viral_dropdown_component/with_icon')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Organism' # Label is not rendered when only icon is present
        assert_selector '.viral-dropdown--icon svg.icon-bars_3' # Assert icon is present
        assert_no_text 'Aspergillus awamori'
        assert_no_text 'Bacillus cereus'
        assert_no_text 'Pseudomonas aeruginosa'
        # Click the button itself, not by text if label is not there
        find('button[data-viral--dropdown-target="trigger"]').click
        assert_text 'Aspergillus awamori'
        assert_text 'Bacillus cereus'
        assert_text 'Pseudomonas aeruginosa'
      end
    end

    test 'dropdown component with item icons' do
      visit('/rails/view_components/viral_dropdown_component/with_item_icon')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        find('button[data-viral--dropdown-target="trigger"]').click
        assert_text 'Checkmark'
        assert_selector 'li svg.icon-check'
        assert_text 'Inbox'
        assert_selector 'li svg.icon-inbox_stack'
      end
    end

    test 'dropdown component uses custom button_styles when provided' do
      visit('/rails/view_components/viral_dropdown_component/with_custom_button_styles')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        button = find('button')
        assert button[:class].include?('bg-emerald-800'), 'Expected custom button style to be applied'
        assert button[:class].include?('text-white'), 'Expected custom button style to be applied'
        assert_text 'Custom Button'
        click_on 'Custom Button'
        assert_text 'Item 1'
      end
    end

    test 'dropdown component with tooltip' do
      visit('/rails/view_components/viral_dropdown_component/with_tooltip')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        button = find('button')
        assert_equal 'This is a tooltip!', button[:title]
        assert_text 'Tooltip Button'
        click_on 'Tooltip Button'
        assert_text 'Action 1'
      end
    end
  end
end
