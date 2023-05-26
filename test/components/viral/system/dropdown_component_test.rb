# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component with label' do
      visit('/rails/view_components/viral_dropdown_component/with_caret')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Pizza'
        assert_no_text 'Bacon'
        assert_selector '.Viral-Dropdown--button'
        find('.Viral-Dropdown--button').click
        assert_text 'Pizza'
        assert_text 'Bacon'
      end
    end

    test 'dropdown component with icon' do
      visit('/rails/view_components/viral_dropdown_component/with_icon')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Pizza'
        assert_no_text 'Bacon'
        assert_selector '.Viral-Dropdown--icon'
        find('.Viral-Dropdown--icon').click
        assert_text 'Pizza'
        assert_text 'Bacon'
      end
    end
  end
end
