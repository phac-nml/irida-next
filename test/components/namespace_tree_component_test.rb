# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'

class NamespaceTreeComponentTest < ViewComponent::TestCase
  test 'Should render a collapsed tree' do
    namespaces = Array.new(3) { |i| Group.create!(name: "Group GLT #{i + 1}", path: "group-glt-#{i + 1}") }
    namespaces.push(Group.create!(name: 'Group GLT 4', path: 'group-glt-4',
                                  children: [Group.create!(name: 'Group GLT 5', path: 'group-glt-5')]))
    Member.stub :effective_access_level, Member::AccessLevel::OWNER do
      render_inline NamespaceTreeContainerComponent.new(namespaces:, path: 'dashboard_groups_path')

      assert_selector 'div.namespace-entry', count: 4
      assert_selector 'div.namespace-entry', text: 'Group GLT 1'
      assert_selector 'div.namespace-entry a[href="/group-glt-1"]', text: 'Group GLT 1', count: 1
      assert_selector 'div.namespace-entry', text: 'Group GLT 2'
      assert_selector 'div.namespace-entry a[href="/group-glt-2"]', text: 'Group GLT 2', count: 1
      assert_selector 'div.namespace-entry', text: 'Group GLT 3'
      assert_selector 'div.namespace-entry a[href="/group-glt-3"]', text: 'Group GLT 3', count: 1
      assert_selector 'div.namespace-entry', text: 'Group GLT 4'
      assert_selector 'div.namespace-entry a[href="/group-glt-4"]', text: 'Group GLT 4', count: 1
      # verify 4 effective role pills are visible
      assert_selector 'span', text: 'Owner', count: 4
    end
  end
end
