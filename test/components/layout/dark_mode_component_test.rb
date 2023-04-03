# frozen_string_literal: true

require 'test_helper'

module Layout
  class DarkModeComponentTest < ViewComponent::SystemTestCase
    test 'Should toggle dark mode' do
      with_rendered_component_path(render_inline(Layout::DarkModeComponent.new)) do |component|
        assert_selector component, '[data-layout--dark-mode-component-target="darkIcon"]'
        component.click_on 'button'
        assert_selector component, '[data-layout--dark-mode-component-target="lightIcon"]'
      end
    end
  end
end
