# frozen_string_literal: true

require 'application_system_test_case'

module System
  class TooltipComponentTest < ApplicationSystemTestCase
    test 'tooltip appears on hover' do
      visit('/rails/view_components/tooltip_component/default')
      assert_selector '.tooltip', visible: false
      find('.btn').hover
      assert_selector '.tooltip', visible: true
    end
  end
end
