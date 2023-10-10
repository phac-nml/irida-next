# frozen_string_literal: true

require 'application_system_test_case'

class ShowTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
    @group = groups(:group_one)
  end

  test 'visiting the show' do
    visit group_url(@group)
    assert_selector 'h1', text: @group.name

    assert_selector 'a.active', text: I18n.t(:'groups.show.tabs.subgroups_and_projects')
    assert_selector 'li.namespace-entry', count: 21

    click_on I18n.t(:'groups.show.tabs.shared_projects')
    assert_selector 'a.active', text: I18n.t(:'groups.show.tabs.shared_projects')
    assert_selector 'tbody > tr', count: 1
  end
end
