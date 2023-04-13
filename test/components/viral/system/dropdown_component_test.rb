# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component' do
      visit('/rails/view_components/dropdown_component/default')
      assert_no_text 'Item 1'
      assert_no_text 'Item 2'
      click_on 'Items'
      assert_text 'Item 1'
      assert_text 'Item 2'
    end
  end
end
