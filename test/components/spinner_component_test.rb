# frozen_string_literal: true

require 'view_component_test_case'

class SpinnerComponentTest < ViewComponentTestCase
  test 'default' do
    render_inline SpinnerComponent.new(message: 'Still loading..please wait...')
    assert_selector 'div[data-test-selector="spinner"]', count: 1
    assert_text 'Still loading..please wait...'
  end
end
