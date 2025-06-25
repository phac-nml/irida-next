# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  test 'Should render a searchbox' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'

    render_inline SearchComponent.new(query: Member.ransack, url:, search_attribute:, placeholder:)

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text placeholder
  end

  test 'accessibility' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'

    render_inline SearchComponent.new(query: Member.ransack, url:, search_attribute:, placeholder:)

    assert_selector 'form[role^="search"]', count: 1
    assert_selector 'input[type^="search"]', count: 1
  end
end
