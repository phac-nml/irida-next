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
end
