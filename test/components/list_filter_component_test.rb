# frozen_string_literal: true

require 'view_component_test_case'

class ListFilterComponentTest < ViewComponentTestCase
  test 'default' do
    render_preview(:default)
    find("button[aria-label='#{I18n.t(:'components.list_filter.title')}").click
    within 'dialog' do
      assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
      find("input[type='text']").send_keys 'SNAFU, FUBAR'
      assert_selector 'span.label', count: 2
      assert_selector 'span.label', text: 'FUBAR'
      assert_selector 'span.label', text: 'SNAFU'
      click_button I18n.t(:'components.list_filter.apply')
    end
  end
end
