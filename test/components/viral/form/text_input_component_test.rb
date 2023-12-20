# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class TextInputComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)

        assert_selector 'input[type="text"]', count: 1
      end
    end
  end
end
