# frozen_string_literal: true

require 'application_system_test_case'

module System
  class ClipboardComponentTest < ApplicationSystemTestCase
    test 'clipboard component' do
      visit('/rails/view_components/clipboard_component/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        find('button', text: 'Copy to clipboard').click
        assert_no_text 'Copy to clipboard'
        assert_text 'Copied!'
      end
    end
  end
end
