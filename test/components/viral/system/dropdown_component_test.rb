# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component with label' do
      visit('/rails/view_components/dropdown_component/with_label_and_caret')
      assert_no_text 'Item 1'
      assert_no_text 'Item 2'
      find('.Viral-Dropdown--button').click
      assert_text 'Item 1'
      assert_text 'Item 2'
    end

    test 'dropdown component with icon' do
      visit('/rails/view_components/dropdown_component/with_icon')
      assert_no_text 'Item 1'
      assert_no_text 'Item 2'
      find('.Viral-Dropdown--icon').click
      assert_text 'Item 1'
      assert_text 'Item 2'
    end
  end
end
