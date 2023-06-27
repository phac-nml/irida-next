# frozen_string_literal: true

require 'application_system_test_case'

class ConfirmationComponentTest < ApplicationSystemTestCase
  test 'basic confirmation component' do
    visit('/rails/view_components/confirmation_component/default')
    find('button', text: 'Confirmation').click
    assert_text 'Confirmation required'
    assert_text 'Custom modal text here!'
    find('button', text: 'Cancel').click
    assert_no_selector 'dialog'
  end

  test 'confirmation component with custom content' do
    visit('/rails/view_components/confirmation_component/custom_content')
    find('button', text: 'Confirmation').click
    assert_text 'Confirmation required'
    assert_selector 'div.border-blue-300.bg-blue-50'
    find('button', text: 'Cancel').click
    assert_no_selector 'dialog'
  end

  test 'confirmation component with custom form' do
    visit('/rails/view_components/confirmation_component/with_custom_form')
    find('button', text: 'Create project').click
    assert_text 'Confirmation required'
    assert_selector 'input[type=text]'
    find('button', text: 'Cancel').click
    assert_no_selector 'dialog'
  end
end
