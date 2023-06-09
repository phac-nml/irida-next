# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DialogComponentTest < ApplicationSystemTestCase
    test 'default' do
      visit('rails/view_components/viral_dialog_component/default')
      within('dialog') do
        assert_accessible

        assert_text 'This is the default dialog'
      end
    end

    test 'small' do
      visit('rails/view_components/viral_dialog_component/small')
      within('dialog.dialog--size-sm') do
        assert_accessible
        assert_text 'This is the small dialog'
      end
    end

    test 'large' do
      visit('rails/view_components/viral_dialog_component/large')
      within('dialog.dialog--size-lg') do
        assert_accessible
        assert_text 'This is the large dialog'
      end
    end

    test 'extra large' do
      visit('rails/view_components/viral_dialog_component/extra_large')
      within('dialog.dialog--size-xl') do
        assert_accessible
        assert_text 'This is the extra large dialog'
      end
    end

    test 'with primary action' do
      visit('rails/view_components/viral_dialog_component/with_primary_action')
      within('dialog') do
        assert_accessible
        assert_selector 'button.button--state-primary', count: 1
        assert_selector 'button.button--state-default', count: 1
      end
    end

    test 'with trigger' do
      visit('rails/view_components/viral_dialog_component/with_trigger')
      click_button('Open dialog')
      within('dialog') do
        assert_accessible
        assert_text 'This is a dialog with a trigger'
        find('button[aria-label="Close dialog"]').click
      end
    end

    test 'with multiple sections' do
      visit('rails/view_components/viral_dialog_component/with_multiple_sections')
      within('dialog') do
        assert_accessible
        assert_selector 'hr', count: 1
      end
    end
  end
end
