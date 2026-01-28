# frozen_string_literal: true

require 'application_system_test_case'

module Pathogen
  module System
    class TooltipComponentTest < ApplicationSystemTestCase
      setup do
        @link_text = 'This is a link with tooltip'
        @tooltip_text = 'Tooltip text'
      end

      test 'tooltip appears on hover & disappears on escape' do
        visit('/rails/view_components/pathogen/link/tooltip')
        within('.Viral-Preview > [data-controller-connected="true"]', wait: 2) do
          # Invoke tooltip on hover
          find('a', text: @link_text).hover
          # Wait for tooltip to appear with visible classes
          assert_selector '[data-pathogen--tooltip-target="tooltip"].opacity-100.visible', text: @tooltip_text, wait: 2
        end
        # Dismiss tooltip on escape (send to body since handler is on document)
        page.find('body').send_keys(:escape)
        # Wait for tooltip to hide
        assert_selector '[data-pathogen--tooltip-target="tooltip"].opacity-0.invisible', visible: :all, wait: 2
      end

      test 'tooltip appears on focus & disappears on blur' do
        visit('/rails/view_components/pathogen/link/tooltip')
        link_element = nil
        within('.Viral-Preview > [data-controller-connected="true"]', wait: 2) do
          # Invoke tooltip on focus using JavaScript
          link_element = find('a', text: @link_text)
          page.execute_script('arguments[0].focus()', link_element.native)
          # Wait for tooltip to appear with visible classes
          assert_selector '[data-pathogen--tooltip-target="tooltip"].opacity-100.visible', text: @tooltip_text, wait: 2
        end
        # Dismiss tooltip on blur by calling blur directly on the link
        page.execute_script('arguments[0].blur()', link_element.native)
        # Wait for tooltip to hide
        assert_selector '[data-pathogen--tooltip-target="tooltip"].opacity-0.invisible', visible: :all, wait: 2
      end
    end
  end
end
