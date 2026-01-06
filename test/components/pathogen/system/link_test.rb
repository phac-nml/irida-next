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
        within('.Viral-Preview > [data-controller-connected="true"]') do
          # Invoke tooltip on hover
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: false
          find('a', text: @link_text).hover
          assert_text @tooltip_text
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: true
          # Dismiss tooltip on escape
          find('a', text: @link_text).send_keys(:escape)
          assert_no_text  @tooltip_text
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: false
        end
      end

      test 'tooltip appears on focus & disappears on blur' do
        visit('/rails/view_components/pathogen/link/tooltip')
        within('.Viral-Preview > [data-controller-connected="true"]') do
          # Invoke tooltip on focus
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: false
          find('a', text: @link_text).trigger('focus')
          assert_text @tooltip_text
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: true
          # Dismiss tooltip on blur
          find('a', text: @link_text).send_keys(:tab)
          assert_no_text  @tooltip_text
          assert_selector '[data-pathogen--tooltip-target="target"]', visible: false
        end
      end
    end
  end
end
