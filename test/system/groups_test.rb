# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'visiting the groups page' do
    visit groups_url

    assert_selector 'h1', text: I18n.t(:'groups.show.title')
  end
end
