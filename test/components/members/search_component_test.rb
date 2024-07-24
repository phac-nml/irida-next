# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  test 'Should render a searchbox' do
    tab = ''
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    url = '/-/groups/group-1/-/members'
    render_inline SearchComponent.new(Member.ransack, tab, url, search_attribute, placeholder)

    assert_selector "input[type='hidden'][name='tab'][value='#{tab}']", visible: false, count: 1
    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text placeholder
  end
end
