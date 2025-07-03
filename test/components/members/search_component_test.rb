# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  test 'Should render a searchbox' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    total_count = 0

    render_inline SearchComponent.new(query: Member.ransack, url:, search_attribute:, placeholder:, total_count:)

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text placeholder
  end

  test 'accessibility' do
    with_request_url '/-/groups/group-1/-/members?q%5Bs%5D=user_email+asc&q%5Buser_email_cont%5D=user&tab=&format=turbo_stream' do # rubocop:disable Layout/LineLength
      url = '/-/groups/group-1/-/members?q%5Bs%5D=user_email+asc&q%5Buser_email_cont%5D=user&tab=&format=turbo_stream'
      search_attribute = :user_email_cont
      placeholder = 'a placeholder'
      total_count = 0
      search_term = 'user'

      render_inline SearchComponent.new(query: Member.ransack, url:, search_attribute:, placeholder:, total_count:)

      assert_selector 'div[role^="status"]', count: total_count,
                                             text: I18n.t(:'components.search.results_message.zero',
                                                          search_term:)
    end
  end
end
