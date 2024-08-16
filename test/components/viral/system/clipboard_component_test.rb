# frozen_string_literal: true

require 'application_system_test_case'

module System
  class ClipboardComponentTest < ApplicationSystemTestCase
    test 'clipboard component' do
      visit('/rails/view_components/clipboard_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        click_button 'Copy to clipboard'
        assert_no_text 'Copy to clipboard'
        assert_text 'Copied!'

        assert_accessible
      end
    end
  end
end
