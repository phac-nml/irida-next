# frozen_string_literal: true

require 'test_helper'

module Navigation
  class CollapseComponentTest < ViewComponent::TestCase
    def test_collapse_componet_renders_button_with_icon
      render_inline Navigation::CollapseComponent.new

      assert_selector 'button'
      assert_selector 'svg.w-5.h-5'
    end
  end
end
