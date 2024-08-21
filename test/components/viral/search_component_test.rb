# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class SearchComponentTest < ViewComponentTestCase
    test 'default' do
      render_inline(:default)
      assert_selector 'div', count: 1
      assert_selector 'input[type="search"]', count: 1
    end
  end
end
