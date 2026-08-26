# frozen_string_literal: true

require 'application_system_test_case'

module Viral
  class DialogComponentSystemTest < ApplicationSystemTestCase
    test 'confirmation dialog' do
      visit('rails/view_components/viral_dialog_component/confirmation')
      within('div[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_text 'Confirmation required'
        assert_selector 'button.button-primary', count: 1
        assert_selector 'button.button-default', count: 1
      end
    end

    test 'default dialog' do
      visit('rails/view_components/viral_dialog_component/default')
      within('div[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_text 'This is the default dialog'
      end
    end

    test 'small dialog' do
      visit('rails/view_components/viral_dialog_component/small')
      within('div[data-controller-connected="true"] dialog.dialog--size-sm') do
        assert_accessible
        assert_text 'This is the small dialog'
      end
    end

    test 'large dialog' do
      visit('rails/view_components/viral_dialog_component/large')
      within('div[data-controller-connected="true"] dialog.dialog--size-lg') do
        assert_accessible
        assert_text 'This is the large dialog'
      end
    end

    test 'extra_large dialog' do
      visit('rails/view_components/viral_dialog_component/extra_large')
      within('div[data-controller-connected="true"] dialog.dialog--size-xl') do
        assert_accessible
        assert_text 'This is the extra large dialog'
      end
    end

    test 'with_action_buttons dialog' do
      visit('rails/view_components/viral_dialog_component/with_action_buttons')
      within('div[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_selector 'button.button-primary', count: 1
        assert_selector 'button.button-default', count: 1
      end
    end

    test 'with_trigger dialog' do
      visit('rails/view_components/viral_dialog_component/with_trigger')
      within 'div[data-controller-connected="true"]' do
        click_button 'Open dialog'
        within 'dialog' do
          # verify accessibility
          assert_accessible
          assert_text 'This is a dialog with a trigger'

          # verify the dialog has a close button
          assert_button I18n.t('components.dialog.close')

          click_button I18n.t('components.dialog.close')
        end

        assert_button 'Open dialog', focused: true
      end
    end

    test 'non closable dialog' do
      visit('rails/view_components/viral_dialog_component/non_closable')
      within 'div[data-controller-connected="true"]' do
        within 'dialog' do
          assert_selector '.dialog--header'

          # verify the dialog does not have a visible close button
          assert_button I18n.t('components.dialog.close'), visible: :hidden
        end
      end
    end
  end
end
