# frozen_string_literal: true

require 'test_helper'

module GroupLinks
  class GroupUnlinkServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'unshare group b with group a' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 2
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end

    test 'share group b with group a then unshare' do
      group = groups(:group_one)
      namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }
      namespace_group_link = nil

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        namespace_group_link = GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 4
      assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end

    test 'unshare group b with group a with invalid permissions' do
      user = users(:ryan_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupUnlinkService.new(user, namespace_group_link).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :unlink_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.unlink_namespace_with_group?',
                          name: namespace_group_link.namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'unshare groub b with group a when no link exists' do
      namespace_group_link = nil
      assert_not GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      assert_no_enqueued_emails
    end

    test 'valid authorization to unshare group' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_authorized_to(:unlink_namespace_with_group?, namespace_group_link.namespace,
                           with: GroupPolicy,
                           context: { user: @user }) do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 2
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end

    test 'unshare project with group' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 2
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end

    test 'share project with group then unshare' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }
      namespace_group_link = nil

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        namespace_group_link = GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 4
      assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end

    test 'unshare project with group with invalid permissions' do
      user = users(:ryan_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupUnlinkService.new(user, namespace_group_link).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :unlink_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.unlink_namespace_with_group?',
                          name: namespace_group_link.namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'valid authorization to unshare project' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_authorized_to(:unlink_namespace_with_group?, namespace_group_link.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        GroupLinks::GroupUnlinkService.new(@user, namespace_group_link).execute
      end

      assert_enqueued_emails 2
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                 args: [Member.user_emails(namespace_group_link.group),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
      assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                 args: [Member.manager_emails(namespace_group_link.namespace),
                                        namespace_group_link.group,
                                        namespace_group_link.namespace]
    end
  end
end
