# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    module Prefixed
      class BooleanComponentTest < ViewComponentTestCase
        test 'default' do
          render_preview(:default)
          assert_selector 'span.font-mono', text: '--prefix', count: 1
          assert_selector 'input[type="radio"]', count: 2
          assert_selector 'input[type="radio"][value="true"][checked="checked"]', count: 1
          assert_no_selector 'input[type="radio"][value="false"][checked="checked"]'
        end

        test 'with_icon' do
          render_preview(:with_icon)
          assert_selector 'span.viral-icon.viral-icon--colorWarning', count: 1
          assert_selector 'input[type="radio"]', count: 2
          assert_selector 'input[type="radio"][value="true"][checked="checked"]', count: 1
          assert_no_selector 'input[type="radio"][value="false"][checked="checked"]'
        end

        test 'with_false_value' do
          render_preview(:with_false_value)
          assert_selector 'span.font-mono', text: '--prefix', count: 1
          assert_selector 'input[type="radio"]', count: 2
          assert_no_selector 'input[type="radio"][value="true"][checked="checked"]'
          assert_selector 'input[type="radio"][value="false"][checked="checked"]', count: 1
        end
      end
    end
  end
end
