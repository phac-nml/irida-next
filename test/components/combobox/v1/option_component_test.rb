# frozen_string_literal: true

require 'view_component_test_case'

module Combobox
  module V1
    class OptionComponentTest < ViewComponentTestCase
      test 'renders label when no content is provided' do
        render_inline(OptionComponent.new(value: 'user-1', label: 'User 1'))

        assert_selector '[role="option"][data-value="user-1"][data-label="User 1"]', text: 'User 1'
      end
    end
  end
end
