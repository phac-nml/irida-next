# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  test 'visiting the index' do
    login_as users(:john_doe)
    visit groups_url

    assert_selector 'h1', text: 'Your Groups'
  end
end
