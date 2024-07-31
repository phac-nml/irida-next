# frozen_string_literal: true

require 'test_helper'

module Groups
  class TableComponentTest < ViewComponent::TestCase
    test 'Should render a table of invited groups for a group' do
      with_request_url '/-/groups/group-1/-/members?tab=invited_groups' do
        namespace = groups(:group_one)
        user = users(:john_doe)
        namespace_group_links = NamespaceGroupLink.for_namespace_and_ancestors(namespace).not_expired
        q = NamespaceGroupLink.ransack

        render_inline TableComponent.new(
          namespace_group_links,
          namespace,
          Member::AccessLevel.access_level_options_owner,
          q,
          abilities: {
            update_namespace: true,
            unlink_group: true
          }
        )

        assert_selector 'table', count: 1
        assert_selector 'table thead th', count: 6
        assert_selector 'table tbody tr', count: namespace_group_links.count
        namespace_group_links.each do |namespace_group_link|
          assert_selector 'table tbody tr td:nth-child(1)', text: namespace_group_link.group.name
          assert_selector 'table tbody tr td:nth-child(4)',
                          text: Member::AccessLevel.human_access(namespace_group_link.group_access_level)
        end
      end
    end

    test 'Should render a table of invited groups for a project' do
      with_request_url '/group-1/project-1/-/members?tab=invited_groups' do
        project = projects(:project1)
        namespace = project.namespace
        namespace_group_links = NamespaceGroupLink.for_namespace_and_ancestors(namespace).not_expired
        q = NamespaceGroupLink.ransack

        render_inline TableComponent.new(
          namespace_group_links,
          namespace,
          Member::AccessLevel.access_level_options_owner,
          q,
          abilities: {
            update_namespace: true,
            unlink_group: true
          }
        )

        assert_selector 'table', count: 1
        assert_selector 'table thead th', count: 6
        assert_selector 'table tbody tr', count: namespace_group_links.count
        namespace_group_links.each do |namespace_group_link|
          assert_selector 'table tbody tr td:nth-child(1)', text: namespace_group_link.group.name
          assert_selector 'table tbody tr td:nth-child(4)',
                          text: Member::AccessLevel.human_access(namespace_group_link.group_access_level)
        end
      end
    end
  end
end
