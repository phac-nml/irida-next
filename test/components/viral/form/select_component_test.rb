# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class SelectComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)
        assert_selector 'option', count: 3
      end

      test 'default option' do
        render_preview(:selected_option)
        assert_selector 'option', count: 3
        assert_selector 'option[value="2"][selected]', count: 1
      end
    end
  end
end
