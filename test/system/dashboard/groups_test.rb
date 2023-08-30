# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class GroupsTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
    end

    test 'can see the list of groups' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')
    end
  end
end
