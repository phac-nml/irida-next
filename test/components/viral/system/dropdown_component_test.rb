# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DropdownComponentTest < ApplicationSystemTestCase
    test 'dropdown component with label' do
      visit('/rails/view_components/viral_dropdown_component/with_caret')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Aspergillus awamori'
        assert_no_text 'Bacillus cereus'
        assert_no_text 'Pseudomonas aeruginosa'
        assert_selector '.viral-dropdown--button'
        click_on 'Organism'
        assert_text 'Aspergillus awamori'
        assert_text 'Bacillus cereus'
        assert_text 'Pseudomonas aeruginosa'
      end
    end

    test 'dropdown component with icon' do
      visit('/rails/view_components/viral_dropdown_component/with_icon')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_no_text 'Aspergillus awamori'
        assert_no_text 'Bacillus cereus'
        assert_no_text 'Pseudomonas aeruginosa'
        assert_selector '.viral-dropdown--icon'
        click_on 'Organism'
        assert_text 'Aspergillus awamori'
        assert_text 'Bacillus cereus'
        assert_text 'Pseudomonas aeruginosa'
      end
    end
  end
end
