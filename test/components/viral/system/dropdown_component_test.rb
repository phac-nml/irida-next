# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component default rendering' do
      visit('/rails/view_components/viral_dropdown_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_text 'Organism'
        assert_no_selector 'svg' # No caret by default

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
        assert_selector 'svg' # Assert caret is present
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
        assert_selector 'svg.plus-circle-icon' # Assert icon is present
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
        assert_selector 'li svg.check-icon'
        assert_text 'Inbox'
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

    test 'dropdown component with data attributes on items' do
      visit('/rails/view_components/viral_dropdown_component/with_data_attributes')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_text 'Data Attributes Test'
        click_on 'Data Attributes Test'

        # Check that data attributes are properly rendered
        first_item = find('a[href="#"]', text: 'Item with Data')
        assert_equal 'click->test#action', first_item['data-action']
        assert_equal 'dropdown-item-1', first_item['data-test-id']
        assert_equal 'Are you sure?', first_item['data-confirm']

        # Check that custom classes are properly merged
        second_item = find('a[href="#"]', text: 'Another Item')
        assert_equal 'dropdown-item-2', second_item['data-test-id']
        assert_equal 'delete', second_item['data-turbo-method']
        assert second_item[:class].include?('text-red-600'), 'Expected custom class to be applied'
      end
    end
  end
end
