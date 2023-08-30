# frozen_string_literal: true

require 'test_helper'

class GroupListTreeComponentTest < ViewComponent::TestCase
  test 'Should render a collapsed tree' do
    groups = Array.new(3) { |i| Group.new(id: i, name: "Group #{i}") }
    render_inline GroupsListTreeContainerComponent.new(groups:, path: 'dashboard_groups_path')

    assert_selector 'li', text: 'Group 0'
    assert_selector 'li', text: 'Group 1'
    assert_selector 'li', text: 'Group 2'
  end
end
