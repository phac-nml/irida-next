# frozen_string_literal: true

require 'application_system_test_case'

module System
  class FlashComponentTest < ApplicationSystemTestCase
    test 'flash message with javascript closes' do
      visit('/rails/view_components/viral_flash_component/success_flash')
      message = 'Success Message!'

      assert_text message
      assert_selector '.text-green-500.bg-green-100'
      click_button 'Close'
      assert_no_text message
    end
  end
end
