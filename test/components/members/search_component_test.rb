# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  test 'Should render a searchbox' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'

    render_inline SearchComponent.new(q: Member.ransack, url:, search_attribute:,
                                      placeholder:)

    assert_selector "input[type='hidden'][name='tab'][value='']", visible: false, count: 1
    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text placeholder
  end

  test 'Should render a searchbox with a tab' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    tab = 'invited_groups'

    render_inline SearchComponent.new(q: Member.ransack, url:, search_attribute:,
                                      placeholder:, tab:)

    assert_selector "input[type='hidden'][name='tab'][value='#{tab}']", visible: false, count: 1
    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text placeholder
  end
end
