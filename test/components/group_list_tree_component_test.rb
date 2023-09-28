# frozen_string_literal: true

require 'test_helper'

class GroupListTreeComponentTest < ViewComponent::TestCase
  test 'Should render a collapsed tree' do
    groups = Array.new(3) { |i| Group.create!(name: "Group GLT #{i + 1}", path: "group-glt-#{i + 1}") }
    groups.push(Group.create!(name: 'Group GLT 4', path: 'group-glt-4',
                              children: [Group.create!(name: 'Group GLT 5', path: 'group-glt-5')]))
    render_inline NamespaceTreeContainerComponent.new(groups:, path: 'dashboard_groups_path')

    assert_selector 'li', count: 4
    assert_selector 'li', text: 'Group GLT 1'
    assert_selector 'li a[href="/group-glt-1"][aria-label="Group GLT 1"]', count: 1
    assert_selector 'li', text: 'Group GLT 2'
    assert_selector 'li a[href="/group-glt-2"][aria-label="Group GLT 2"]', count: 1
    assert_selector 'li', text: 'Group GLT 3'
    assert_selector 'li a[href="/group-glt-3"][aria-label="Group GLT 3"]', count: 1
    assert_selector 'li', text: 'Group GLT 4'
    assert_selector 'li a[href="/group-glt-4"][aria-label="Group GLT 4"]', count: 1
  end
end
