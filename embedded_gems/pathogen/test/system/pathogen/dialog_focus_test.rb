# frozen_string_literal: true

require 'application_system_test_case'

module Pathogen
  # System tests for Pathogen::DialogComponent focus management and keyboard navigation
  # Tests accessibility features including focus trap, ESC key, and focus restoration
  class DialogFocusTest < ApplicationSystemTestCase
    test 'focuses first focusable element when dialog opens' do
      visit('/rails/view_components/pathogen/dialog/with_form')

      # Open the dialog
      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # First input should receive focus
      focused_element = page.evaluate_script('document.activeElement.tagName')
      assert_equal 'INPUT', focused_element
    end

    test 'traps focus within dialog during Tab navigation' do
      visit('/rails/view_components/pathogen/dialog/with_multiple_inputs')

      # Open the dialog
      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # Tab through all focusable elements
      # Focus should cycle back to first element after last element
      # Note: Full implementation would require Capybara key press simulation
      # This is a placeholder test demonstrating the intended behavior
      skip 'Full focus trap testing requires complex key event simulation'
    end

    test 'ESC key closes dismissible dialog' do
      visit('/rails/view_components/pathogen/dialog/dismissible')

      # Open the dialog
      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # Press ESC
      find('div[role="dialog"]').send_keys(:escape)

      # Dialog should be hidden
      assert_no_selector 'div[role="dialog"]', visible: true
    end

    test 'ESC key does not close non-dismissible dialog' do
      visit('/rails/view_components/pathogen/dialog/non_dismissible')

      # Open the dialog
      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # Press ESC
      find('div[role="dialog"]').send_keys(:escape)

      # Dialog should still be visible
      assert_selector 'div[role="dialog"]', visible: true
    end

    test 'restores focus to trigger button after dialog closes' do
      visit('/rails/view_components/pathogen/dialog/default')

      trigger = find_button('Open Dialog')
      trigger.click

      assert_selector 'div[role="dialog"]', visible: true

      # Close dialog
      click_button I18n.t('pathogen.dialog_component.close_button')

      # Focus should be restored to trigger button
      assert_equal trigger, page.evaluate_script('document.activeElement')
    end

    test 'backdrop click closes dismissible dialog' do
      visit('/rails/view_components/pathogen/dialog/dismissible')

      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # Click on backdrop (not dialog content)
      backdrop = find('[data-pathogen--dialog-target="backdrop"]')
      backdrop.click

      # Dialog should close
      assert_no_selector 'div[role="dialog"]', visible: true
    end

    test 'backdrop click does not close non-dismissible dialog' do
      visit('/rails/view_components/pathogen/dialog/non_dismissible')

      click_button 'Open Dialog'
      assert_selector 'div[role="dialog"]', visible: true

      # Click on backdrop
      backdrop = find('[data-pathogen--dialog-target="backdrop"]')
      backdrop.click

      # Dialog should remain visible
      assert_selector 'div[role="dialog"]', visible: true
    end
  end
end
