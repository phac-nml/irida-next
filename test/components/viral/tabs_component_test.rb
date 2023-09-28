# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class TabsComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)

      assert_selector 'ul[role="tablist"][aria-label="Demo tabs"]' do
        assert_selector 'li[role="presentation"]' do
          assert_selector 'a[role="tab"][aria-controls="demo-tabs"][aria-selected="true"]', text: 'First tab', count: 1
          assert_selector 'a[role="tab"][aria-controls="demo-tabs"][aria-selected="false"]', text: 'Second tab',
                                                                                             count: 1
        end
      end

      assert_selector 'div[role="region"][aria-live="polite"]', text: 'Turbo frames go in here', count: 1
    end
  end
end
