# frozen_string_literal: true

require 'application_system_test_case'

class ConfirmationComponentTest < ApplicationSystemTestCase
  test 'basic confirmation component' do
    visit('/rails/view_components/confirmation_component/default')
    click_button 'Confirmation'
    assert_text 'Confirmation required'
    assert_text 'Custom modal text here!'
    assert_accessible
    click_button 'Cancel'
    assert_no_selector 'dialog'
    assert_accessible
  end

  test 'confirmation component with custom content' do
    visit('/rails/view_components/confirmation_component/custom_content')
    click_button 'Confirmation'
    assert_text 'Confirmation required'
    assert_selector 'div.border-blue-300.bg-blue-50'
    assert_accessible
    click_button 'Cancel'
    assert_no_selector 'dialog'
    assert_accessible
  end

  test 'confirmation component with custom value' do
    visit('/rails/view_components/confirmation_component/with_confirm_value')
    click_button 'Delete project'
    assert_selector 'button.button--state-destructive:disabled'
    assert_text 'Confirmation required'
    assert_accessible
    find('input').set 'Project X' # TODO: update this to use fill_in
    assert_selector 'button.button--state-destructive'
    assert_accessible
  end
end
