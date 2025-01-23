# frozen_string_literal: true

require 'application_system_test_case'

module System
  class ListFilterComponentTest < ApplicationSystemTestCase
    puid1 = 'INXT_SAM_AYDIB56V5B'
    puid2 = 'INXT_SAM_AYDIB56VRB'

    test 'default' do
      visit('rails/view_components/list_filter_component/default')
      within 'span[data-controller-connected="true"]' do
        click_button I18n.t(:'components.list_filter.title')
        within 'dialog' do
          assert_accessible
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          fill_in I18n.t(:'components.list_input.description'), with: "#{puid1}, #{puid2}"
          assert_selector 'span.label', count: 1
          assert_selector 'span.label', text: puid1
          find('input').text puid2
          click_button I18n.t(:'components.list_filter.apply')
        end
        assert_selector 'span[data-list-filter-target="count"]', text: '2'

        click_button I18n.t(:'components.list_filter.title')
        within 'dialog' do
          assert_accessible
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          assert_selector 'span.label', count: 2
          assert_selector 'span.label', text: puid1
          assert_selector 'span.label', text: puid2
          click_button I18n.t(:'components.list_input.clear')
          assert_selector 'span.label', count: 0
          click_button I18n.t(:'components.list_filter.apply')
        end
        assert_no_selector 'span[data-list-filter-target="count"]'
      end
    end
  end
end
