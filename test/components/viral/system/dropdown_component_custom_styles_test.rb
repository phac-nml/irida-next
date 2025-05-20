# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component uses custom button_styles when provided' do
      visit('/rails/view_components/viral_dropdown_component/with_custom_button_styles')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        button = find('button')
        assert button[:class].include?('bg-emerald-800'), 'Expected custom button style to be applied'
        assert button[:class].include?('text-white'), 'Expected custom button style to be applied'
      end
    end
  end
end
