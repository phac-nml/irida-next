# frozen_string_literal: true

require 'view_component_system_test_case'

module Layout
  class DarkModeComponentTest < ViewComponentSystemTestCase
    test 'Should toggle dark mode' do
      with_rendered_component_path(render_inline(Layout::DarkModeComponent.new)) do |path|
        visit path
        assert_selector '[data-layout--dark-mode-component-target="darkIcon"]'
        find('[data-layout--dark-mode-component-target="themeToggle"]').click
        assert_selector '[data-layout--dark-mode-component-target="lightIcon"]'
      end
    end
  end
end
