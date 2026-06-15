# frozen_string_literal: true

require 'view_component_test_case'

module Dropdown
  class ComponentVersioningTest < ViewComponentTestCase
    test 'renders v1 when feature flag is disabled' do
      Flipper.disable(:v2_dropdown)
      render_component

      assert_selector '[data-controller="dropdown--v1"]'
      assert_selector '[data-dropdown--v1-target="trigger"]'
      assert_selector '[data-dropdown--v1-target="menu"]', visible: :hidden
    end

    test 'renders v2 when feature flag is enabled' do
      Flipper.enable(:v2_dropdown)
      render_component

      assert_selector '[data-controller="dropdown--v2"]'
      assert_selector '[data-dropdown--v2-target="trigger"]'
      assert_selector '[data-dropdown--v2-target="menu"]', visible: :hidden
    end

    test 'renders v1 when version override is v1' do
      render_component(version: :v1)

      assert_selector '[data-controller="dropdown--v1"]'
      assert_selector '[data-dropdown--v1-target="trigger"]'
      assert_selector '[data-dropdown--v1-target="menu"]', visible: :hidden
    end

    test 'renders v2 when version override is v2' do
      render_component(version: :v2)

      assert_selector '[data-controller="dropdown--v2"]'
      assert_selector '[data-dropdown--v2-target="trigger"]'
      assert_selector '[data-dropdown--v2-target="menu"]', visible: :hidden
    end

    test 'raises when version override is invalid' do
      assert_raises(ArgumentError) do
        render_component(version: :v3)
      end
    end

    test 'renders custom trigger content when compact_trigger is enabled in v1' do
      Flipper.disable(:v2_dropdown)
      render_inline DropdownComponent.new(
        compact_trigger: true,
        aria: { label: 'Account menu' }
      ) do |dropdown|
        dropdown.with_trigger do
          '<span class="avatar">AB</span>'.html_safe
        end
        dropdown.with_item(label: 'Profile', url: '#')
      end

      assert_selector 'button[aria-label="Account menu"] span.avatar', text: 'AB'
      assert_no_selector 'svg'
    end

    test 'renders custom trigger content when compact_trigger is enabled in v2' do
      Flipper.enable(:v2_dropdown)
      render_inline DropdownComponent.new(
        compact_trigger: true,
        aria: { label: 'Account menu' }
      ) do |dropdown|
        dropdown.with_trigger do
          '<span class="avatar">AB</span>'.html_safe
        end
        dropdown.with_item(label: 'Profile', url: '#')
      end

      assert_selector 'button[aria-label="Account menu"] span.avatar', text: 'AB'
      assert_no_selector 'svg'
    end

    private

    def render_component(version: nil)
      render_inline DropdownComponent.new(version: version, label: 'Organism',
                                          aria: { label: 'Organism dropdown list' },
                                          title: 'Organisms that really shine') do |dropdown|
        dropdown.with_item(label: 'Aspergillus awamori', url: '#')
        dropdown.with_item(label: 'Bacillus cereus', url: '#')
        dropdown.with_item(label: 'Pseudomonas aeruginosa', url: '#')
      end
    end
  end
end
