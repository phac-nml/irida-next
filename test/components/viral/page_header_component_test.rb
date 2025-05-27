# frozen_string_literal: true

require 'application_system_test_case'

class PageHeaderComponentTest < ApplicationSystemTestCase
  test 'renders header' do
    visit('/rails/view_components/viral_page_header_component/with_icon')

    assert_text 'Page header'
    assert_text 'This is a page header'
  end

  test 'renders header with buttons' do
    visit('/rails/view_components/viral_page_header_component/with_buttons')
    assert_selector 'div.page-header button', count: 1
  end

  test 'renders header with icon' do
    visit('/rails/view_components/viral_page_header_component/with_icon')
    assert_selector 'div.page-header svg'
  end

  test 'renders header with avatar' do
    visit('/rails/view_components/viral_page_header_component/with_avatar')
    assert_selector 'div.page-header span.avatar'
  end
end
