# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PagyLimitComponentTest < ViewComponentTestCase
    test 'renders default' do
      render_preview(:default)

      assert_text 'Displaying 1-20 of 100 items'
      assert_selector 'span.font-bold', text: '1-20'
      assert_no_match(/&lt;span/, rendered_content)
    end

    test 'renders with one item' do
      render_preview(:with_one_item)

      assert_text 'Displaying 1 item'
    end
  end
end
