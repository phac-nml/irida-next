# frozen_string_literal: true

require 'test_helper'

module Members
  class TableComponentTest < ViewComponent::TestCase
    test 'Should render a table of group members' do
      with_request_url '/-/groups/group-1/-/members' do
        namespace = groups(:group_one)
        user = users(:john_doe)
        members = Member.for_namespace_and_ancestors(namespace).not_expired
        q = Member.ransack

        render_inline TableComponent.new(
          namespace,
          members,
          Member::AccessLevel.access_level_options_owner,
          q,
          true, # has_members
          user,
          {
            update_member: true,
            destroy_member: true
          }
        )

        assert_selector 'table', count: 1
        assert_selector 'table thead th', count: 6
        assert_selector 'table tbody tr', count: members.count
        members.each do |member|
          assert_selector 'table tbody tr td:nth-child(1)', text: member.user.email
          assert_selector 'table tbody tr td:nth-child(2)', text: Member::AccessLevel.human_access(member.access_level)
        end
      end
    end

    test 'Should render a table of project members' do
      with_request_url '/group-1/project-1/-/members' do
        project = projects(:project1)
        namespace = project.namespace
        user = users(:john_doe)
        members = Member.for_namespace_and_ancestors(namespace).not_expired
        q = Member.ransack

        render_inline TableComponent.new(
          namespace,
          members,
          Member::AccessLevel.access_level_options_owner,
          q,
          true, # has_members
          user,
          {
            update_member: true,
            destroy_member: true
          }
        )

        assert_selector 'table', count: 1
        assert_selector 'table thead th', count: 6
        assert_selector 'table tbody tr', count: members.count
        members.each do |member|
          assert_selector 'table tbody tr td:nth-child(1)', text: member.user.email
          assert_selector 'table tbody tr td:nth-child(2)', text: Member::AccessLevel.human_access(member.access_level)
        end
      end
    end

    test 'Should render translated "by" text correctly with improved layout' do
      with_request_url '/-/groups/group-1/-/members' do
        namespace = groups(:group_one)
        user = users(:john_doe)
        members = Member.for_namespace_and_ancestors(namespace).not_expired
        q = Member.ransack

        # Test English translation
        I18n.with_locale(:en) do
          render_inline TableComponent.new(
            namespace,
            members,
            Member::AccessLevel.access_level_options_owner,
            q,
            true, # has_members
            user,
            {
              update_member: true,
              destroy_member: true
            }
          )

          # Check that "by" appears in English
          assert_text 'by'
        end

        # Test French translation
        I18n.with_locale(:fr) do
          render_inline TableComponent.new(
            namespace,
            members,
            Member::AccessLevel.access_level_options_owner,
            q,
            true, # has_members
            user,
            {
              update_member: true,
              destroy_member: true
            }
          )

          # Check that "par" appears in French
          assert_text 'par'
        end
      end
    end
  end
end
