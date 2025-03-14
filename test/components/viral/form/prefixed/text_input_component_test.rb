# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    module Prefixed
      class TextInputComponentTest < ViewComponentTestCase
        test 'default' do
          render_preview(:default)
          assert_selector 'span.font-mono', text: '--prefix', count: 1
        end

        test 'with_icon' do
          render_preview(:with_icon)
          assert_selector 'span.viral-icon.viral-icon--colorWarning', count: 1
        end
      end
    end
  end
end
