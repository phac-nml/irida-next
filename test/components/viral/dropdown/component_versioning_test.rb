# frozen_string_literal: true

require 'view_component_test_case'

module Dropdown
  class ComponentVersioningTest < ViewComponentTestCase
    test 'renders v1 when version override is v1' do
      render_component(version: :v1)

      assert_selector '[data-controller="viral--dropdown"]'
      assert_selector '[data-viral--dropdown-target="trigger"]'
      assert_selector '[data-viral--dropdown-target="menu"]', visible: :hidden
    end

    test 'renders v2 when version override is v2' do
      render_component(version: :v2)

      assert_selector '[data-controller="viral--beta-dropdown"]'
      assert_selector '[data-viral--beta-dropdown-target="trigger"]'
      assert_selector '[data-viral--beta-dropdown-target="menu"]', visible: :hidden
    end

    test 'raises when version override is invalid' do
      assert_raises(ArgumentError) do
        render_component(version: :v3)
      end
    end

    private

    def render_component(version:)
      render_inline Viral::DropdownComponent.new(version: version, label: 'Organism',
                                                 aria: { label: 'Organism dropdown list' },
                                                 title: 'Organisms that really shine') do |dropdown|
        dropdown.with_item(label: 'Aspergillus awamori', url: '#')
        dropdown.with_item(label: 'Bacillus cereus', url: '#')
        dropdown.with_item(label: 'Pseudomonas aeruginosa', url: '#')
      end
    end
  end
end
