# frozen_string_literal: true

require 'application_system_test_case'

class PageHeaderComponentTest < ApplicationSystemTestCase
  test 'renders header' do
    visit('/rails/view_components/viral_page_header_component/with_icon')

    assert_selector 'h1', text: 'Page header with Icons'
    assert_selector 'p', text: 'This is a page header'
    assert_selector 'section svg.icon-users', count: 1
  end

  test 'renders header with buttons' do
    visit('/rails/view_components/viral_page_header_component/with_buttons')
    assert_selector 'h1', text: 'Page header with buttons'
    assert_selector 'p', text: 'This is a page header'
    assert_selector 'section .button', count: 1
  end

  test 'renders header with avatar' do
    visit('/rails/view_components/viral_page_header_component/with_avatar')
    assert_selector 'h1', text: 'Page header with Icons'
    assert_selector 'p', text: 'This is a page header'
    assert_selector 'section span.avatar'
  end
end
