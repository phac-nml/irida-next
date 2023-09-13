# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class CheckboxComponentTest < ViewComponentTestCase
      def test_default
        render_preview(:default)
        assert_selector 'input[type="checkbox"]', count: 1
      end
    end
  end
end
