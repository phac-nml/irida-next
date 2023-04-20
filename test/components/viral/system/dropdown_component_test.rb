# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component with label' do
      visit('/rails/view_components/dropdown_component/with_label_and_caret')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Item 1'
        assert_no_text 'Item 2'
        assert_selector '.Viral-Dropdown--button'
        find('.Viral-Dropdown--button').click
        assert_text 'Item 1'
        assert_text 'Item 2'
      end
    end

    test 'dropdown component with icon' do
      visit('/rails/view_components/dropdown_component/with_icon')
      within('.Viral-Preview  > [data-controller-connected="true"]') do
        assert_no_text 'Item 1'
        assert_no_text 'Item 2'
        assert_selector '.Viral-Dropdown--icon'
        find('.Viral-Dropdown--icon').click
        assert_text 'Item 1'
        assert_text 'Item 2'
      end
    end
  end
end
