# frozen_string_literal: true

require 'application_system_test_case'

module Pathogen
  module System
    class TooltipComponentTest < ApplicationSystemTestCase
      test 'tooltip appears on hover & disappears on escape' do
        visit('/rails/view_components/pathogen_link/tooltip')
        within('.Viral-Preview > [data-controller-connected="true"]') do
          # Invoke tooltip on hover
          assert_selector '[data-viral--tooltip-target="target"]', visible: false
          find('a', text: 'This is a link with tooltip').hover
          assert_text 'Tooltip text'
          assert_selector '[data-viral--tooltip-target="target"]', visible: true
          # Dismiss tooltip by 'Escape' key
          find('a', text: 'This is a link with tooltip').native.send_keys(:escape)
          assert_no_text 'Tooltip text'
          assert_selector '[data-viral--tooltip-target="target"]', visible: false
        end
      end

      test 'tooltip appears on focus & disappears on blur' do
        visit('/rails/view_components/pathogen_link/tooltip')
        within('.Viral-Preview > [data-controller-connected="true"]') do
          # Invoke tooltip on focus
          assert_selector '[data-viral--tooltip-target="target"]', visible: false
          find('a', text: 'This is a link with tooltip').trigger('focus')
          assert_text 'Tooltip text'
          assert_selector '[data-viral--tooltip-target="target"]', visible: true
          # Dismiss tooltip on blur
          find('a', text: 'This is a link with tooltip').native.send_keys(:tab)
          assert_no_text 'Tooltip text'
          assert_selector '[data-viral--tooltip-target="target"]', visible: false
        end
      end
    end
  end
end
