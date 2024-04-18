# frozen_string_literal: true

require 'test_helper'

module GroupLinks
  class GroupLinkUpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'update group to group share access level' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_changes -> { namespace_group_link.group_access_level }, to: Member::AccessLevel::GUEST do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end
      assert_no_enqueued_emails
    end

    test 'update project to group share access level' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_changes -> { namespace_group_link.group_access_level }, to: Member::AccessLevel::GUEST do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end
      assert_no_enqueued_emails
    end

    test 'update group to group share expiration' do
      expiration_date = Date.strptime('2023-08-16', '%Y-%m-%d')
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_changes -> { namespace_group_link.expires_at }, to: expiration_date do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { expires_at: expiration_date }).execute
      end
      assert_no_enqueued_emails
    end

    test 'update project to group share expiration' do
      expiration_date = Date.strptime('2023-08-16', '%Y-%m-%d')
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_changes -> { namespace_group_link.expires_at }, to: expiration_date do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { expires_at: expiration_date }).execute
      end
      assert_no_enqueued_emails
    end

    test 'update group with group share with incorrect permissions' do
      user = users(:david_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupLinkUpdateService.new(user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :update_namespace_with_group_link?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.update_namespace_with_group_link?',
                          name: namespace_group_link.namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'update project with group share with incorrect permissions' do
      user = users(:david_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupLinkUpdateService.new(user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :update_namespace_with_group_link?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_namespace_with_group_link?',
                          name: namespace_group_link.namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'valid authorization to update group to group share' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_authorized_to(:update_namespace_with_group_link?, namespace_group_link.namespace,
                           with: GroupPolicy,
                           context: { user: @user }) do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end
      assert_no_enqueued_emails
    end

    test 'valid authorization to update project to group share' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_authorized_to(:update_namespace_with_group_link?, namespace_group_link.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        GroupLinks::GroupLinkUpdateService.new(@user, namespace_group_link,
                                               { group_access_level: Member::AccessLevel::GUEST }).execute
      end
      assert_no_enqueued_emails
    end

    test 'group to group share is logged using logidze' do
      group_group_link = namespace_group_links(:namespace_group_link2)
      group_group_link.create_logidze_snapshot!
      GroupLinks::GroupLinkUpdateService.new(@user, group_group_link,
                                             { group_access_level: Member::AccessLevel::GUEST }).execute
      group_group_link.create_logidze_snapshot!

      assert_equal 2, group_group_link.log_data.version
      assert_equal 2, group_group_link.log_data.size

      assert_equal Member::AccessLevel::ANALYST, group_group_link.at(version: 1).group_access_level
      assert_equal Member::AccessLevel::GUEST, group_group_link.at(version: 2).group_access_level
    end

    test 'project to group share is logged using logidze' do
      project_group_link = namespace_group_links(:namespace_group_link1)
      project_group_link.create_logidze_snapshot!
      GroupLinks::GroupLinkUpdateService.new(@user, project_group_link,
                                             { group_access_level: Member::AccessLevel::GUEST }).execute
      project_group_link.create_logidze_snapshot!

      assert_equal 2, project_group_link.log_data.version
      assert_equal 2, project_group_link.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, project_group_link.at(version: 1).group_access_level
      assert_equal Member::AccessLevel::GUEST, project_group_link.at(version: 2).group_access_level
    end
  end
end
