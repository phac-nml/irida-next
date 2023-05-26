# frozen_string_literal: true

require 'application_system_test_case'

module System
  class ModalComponentTest < ApplicationSystemTestCase
    test 'with title' do
      title = 'This is a modal title'
      visit('rails/view_components/modal_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_text title
      end
    end

    test 'with title and body' do
      body = 'This is a modal body'
      visit('rails/view_components/modal_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_selector(:xpath, './/div/div/div') do
          assert_text body
        end
      end
    end
  end
end
