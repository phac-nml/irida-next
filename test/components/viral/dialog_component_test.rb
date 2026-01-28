# frozen_string_literal: true

require 'application_system_test_case'

module Viral
  class DialogComponentTest < ApplicationSystemTestCase
    test 'confirmation dialog' do
      visit('rails/view_components/viral_dialog_component/confirmation')
    end

    test 'default dialog' do
      visit('rails/view_components/viral_dialog_component/default')
    end

    test 'small dialog' do
      visit('rails/view_components/viral_dialog_component/small')
    end

    test 'large dialog' do
      visit('rails/view_components/viral_dialog_component/large')
    end

    test 'extra_large dialog' do
      visit('rails/view_components/viral_dialog_component/extra_large')
    end

    test 'with_action_buttons dialog' do
      visit('rails/view_components/viral_dialog_component/with_action_buttons')
    end

    test 'with_trigger dialog' do
      visit('rails/view_components/viral_dialog_component/with_trigger')
      within 'div[data-controller-connected="true"]' do
        click_button 'Open dialog'
        within 'dialog' do
          # verify accessibility
          assert_accessible

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
