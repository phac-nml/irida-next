# frozen_string_literal: true

require 'application_system_test_case'

module System
  class TokenComponentTest < ApplicationSystemTestCase
    test 'token component' do
      visit('/rails/view_components/token_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_selector %(button[data-token-target="maskButton"][aria-pressed="false"])

        find(%(button[data-token-target="maskButton"])).click
        assert_selector %(button[data-token-target="maskButton"][aria-pressed="true"])

        find(%(button[data-token-target="maskButton"])).click
        assert_selector %(button[data-token-target="maskButton"][aria-pressed="false"])

        click_button 'Copy to clipboard'
        assert_no_text 'Copy to clipboard'
        assert_text 'Copied!'

        assert_accessible
      end
    end
  end
end
