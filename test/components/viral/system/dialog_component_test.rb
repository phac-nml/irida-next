# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DialogComponentTest < ApplicationSystemTestCase
    test 'confirmation' do
      visit('rails/view_components/viral_dialog_component/confirmation')
      within('span[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_text 'Confirmation required'
        assert_selector 'button.button--state-primary', count: 1
        assert_selector 'button.button--state-default', count: 1
      end
    end

    test 'default' do
      visit('rails/view_components/viral_dialog_component/default')
      within('span[data-controller-connected="true"] dialog') do
        assert_accessible

        assert_text 'This is the default dialog'
      end
    end

    test 'small' do
      visit('rails/view_components/viral_dialog_component/small')
      within('span[data-controller-connected="true"] dialog.dialog--size-sm') do
        assert_accessible
        assert_text 'This is the small dialog'
      end
    end

    test 'large' do
      visit('rails/view_components/viral_dialog_component/large')
      within('span[data-controller-connected="true"] dialog.dialog--size-lg') do
        assert_accessible
        assert_text 'This is the large dialog'
      end
    end

    test 'extra large' do
      visit('rails/view_components/viral_dialog_component/extra_large')
      within('span[data-controller-connected="true"] dialog.dialog--size-xl') do
        assert_accessible
        assert_text 'This is the extra large dialog'
      end
    end

    test 'with action buttons' do
      visit('rails/view_components/viral_dialog_component/with_action_buttons')
      within('span[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_selector 'button.button--state-primary', count: 1
        assert_selector 'button.button--state-default', count: 1
      end
    end

    test 'with trigger' do
      visit('rails/view_components/viral_dialog_component/with_trigger')
      within('span[data-controller-connected="true"]') do
        click_button('Open dialog')
      end
      within('dialog') do
        assert_accessible
        assert_text 'This is a dialog with a trigger'
        find('button[aria-label="Close dialog"]').click
      end
      assert_selector 'dialog', count: 0
    end

    test 'with multiple sections' do
      visit('rails/view_components/viral_dialog_component/with_multiple_sections')
      within('span[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_selector 'hr', count: 1
      end
    end

    test 'non closable dialog' do
      visit('rails/view_components/viral_dialog_component/non_closable')
      within('span[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_selector 'input[type="text"]', count: 1
        find('input[type="text"]').send_keys :escape
      end
      assert_selector 'span[data-controller-connected="true"] dialog'
    end
  end
end
