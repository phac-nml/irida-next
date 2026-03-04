# frozen_string_literal: true

require 'application_system_test_case'

class SelectionTest < ApplicationSystemTestCase
  test 'shift clicking performs multiselect' do
    visit('/rails/view_components/selection/default')
    assert_selector "div[data-controller='selection']"
    assert_field 'Item 0', checked: false
    assert_field 'Item 1', checked: false
    assert_field 'Item 2', checked: false

    check 'Item 0'
    assert_field 'Item 0', checked: true

    find(:checkbox, 'Item 2').click(:shift)
    assert_field 'Item 0', checked: true
    assert_field 'Item 1', checked: true
    assert_field 'Item 2', checked: true
  end
end
