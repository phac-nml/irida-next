# frozen_string_literal: true

require 'view_component_test_case'

module Layout
  module LanguageSelection
    class ComponentVersioningTest < ViewComponentTestCase
      test 'renders v1 when feature flag is disabled' do
        Flipper.disable(:v2_language_selection)
        render_component

        assert_selector '[data-controller="dropdown--v1"]'
        assert_selector '[data-dropdown--v1-target="trigger"]'
        assert_selector '[data-dropdown--v1-target="menu"]', visible: :hidden
      end

      test 'renders v2 when feature flag is enabled' do
        Flipper.enable(:v2_language_selection)
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

      private

      def render_component(version: nil)
        user = users(:john_doe)

        render_inline(Layout::LanguageSelectionComponent.new(version: version, user: user))
      end
    end
  end
end
