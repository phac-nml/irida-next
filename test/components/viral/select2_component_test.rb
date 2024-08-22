# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class Select2ComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_selector 'div', count: 1
    end
  end
end
