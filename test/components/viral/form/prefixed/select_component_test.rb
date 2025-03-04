# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    module Prefixed
      class SelectComponentTest < ViewComponentTestCase
        test 'default' do
          render_preview(:default)
          assert_selector 'span.font-mono', text: '--prefix', count: 1
          assert_selector 'select', count: 1
          assert_selector 'option', text: 'Lisbon', count: 1
          assert_selector 'option', text: 'Madrid', count: 1
        end

        test 'with_icon' do
          render_preview(:with_icon)
          assert_selector 'span.viral-icon.viral-icon--colorWarning', count: 1
          assert_selector 'select', count: 1
          assert_selector 'option', text: 'Lisbon', count: 1
          assert_selector 'option', text: 'Madrid', count: 1
        end
      end
    end
  end
end
