# frozen_string_literal: true

require 'view_component_system_test_case'

module System
  class FlashComponentTest < ViewComponentSystemTestCase
    def success_message_with_javascript_closes
      visit('/rails/view_components/flash_component/success')
      message = 'Successful Message!'

      assert_text message
      # assert_selector '.bg-green-700'
      # find('[data-action="flash#dismiss"]').click
      # assert_no_text message
    end
  end
end
