# frozen_string_literal: true

require 'application_system_test_case'

module System
  class ModalComponentTest < ApplicationSystemTestCase
    test 'default' do
      visit('rails/view_components/viral_modal_component/default')
      within('dialog') do
        assert_accessible

        assert_text 'This is the default modal'
      end
    end

    test 'small' do
      visit('rails/view_components/viral_modal_component/small')
      within('dialog.modal--size-sm') do
        assert_accessible
        assert_text 'This is the small modal'
      end
    end

    test 'large' do
      visit('rails/view_components/viral_modal_component/large')
      within('dialog.modal--size-lg') do
        assert_accessible
        assert_text 'This is the large modal'
      end
    end

    test 'extra large' do
      visit('rails/view_components/viral_modal_component/extra_large')
      within('dialog.modal--size-xl') do
        assert_accessible
        assert_text 'This is the extra large modal'
      end
    end

    test 'with primary action' do
      visit('rails/view_components/viral_modal_component/with_primary_action')
      within('dialog') do
        assert_accessible
        assert_selector 'button.button--state-primary', count: 1
        assert_selector 'button.button--state-default', count: 1
      end
    end

    test 'with trigger' do
      visit('rails/view_components/viral_modal_component/with_trigger')
      click_button('Open modal')
      within('dialog') do
        assert_accessible
        assert_text 'This is a modal with a trigger'
        find('button[aria-label="Close modal"]').click
      end
    end
  end
end
