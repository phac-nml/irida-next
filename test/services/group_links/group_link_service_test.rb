# frozen_string_literal: true

require 'test_helper'

module GroupLinks
  class GroupLinkServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'share group b with group a' do
      group = groups(:group_one)
      namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end

      assert_enqueued_emails 3
      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                     args: [user_emails, group, namespace, locale]
        end

        manager_emails = Member.manager_emails(namespace, locale)
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                   args: [manager_emails, group, namespace, locale]
      end
    end

    test 'share group a with group a error' do
      group = groups(:group_one)
      # namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_difference -> { NamespaceGroupLink.count } => 0 do
        namespace_group_link = GroupLinks::GroupLinkService.new(@user, group, params).execute
        assert namespace_group_link.errors.full_messages.include? I18n.t('services.groups.share.group_self_reference')
      end

      assert_enqueued_emails 0
    end

    test 'share group b with group a with incorrect permissions' do
      user = users(:ryan_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupLinkService.new(user, namespace, params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :link_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.link_namespace_with_group?',
                          name: namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'share group b with group a where invalid group id' do
      group_id = 1
      namespace = groups(:group_one)
      params = { group_id:, group_access_level: Member::AccessLevel::ANALYST }

      assert_no_difference ['NamespaceGroupLink.count'] do
        GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end
      assert_no_enqueued_emails
    end

    test 'should not be able to share user namespace with group' do
      user = users(:david_doe)
      group = groups(:group_one)
      namespace = namespaces_user_namespaces(:david_doe_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_no_difference ['NamespaceGroupLink.count'] do
        namespace_group_link = GroupLinks::GroupLinkService.new(user, namespace, params).execute
        assert namespace_group_link.errors.full_messages.include?(
          I18n.t('services.groups.share.invalid_namespace_type')
        )
      end

      assert_no_enqueued_emails
    end

    test 'valid authorization to share group with other groups' do
      group = groups(:group_one)
      namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_authorized_to(:link_namespace_with_group?, namespace,
                           with: GroupPolicy,
                           context: { user: @user }) do
        GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end

      assert_enqueued_emails 3
      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                     args: [user_emails, group, namespace, locale]
        end

        manager_emails = Member.manager_emails(namespace, locale)
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                   args: [manager_emails, group, namespace, locale]
      end
    end

    test 'group a shared with group b is logged using logidze' do
      group = groups(:group_one)
      namespace = groups(:group_six)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      group_group_link = GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      group_group_link.create_logidze_snapshot!

      assert_equal 1, group_group_link.log_data.version
      assert_equal 1, group_group_link.log_data.size

      assert_equal group.id, group_group_link.at(version: 1).group.id
      assert_equal namespace.id, group_group_link.at(version: 1).namespace.id
      assert_equal Member::AccessLevel::ANALYST, group_group_link.at(version: 1).group_access_level
    end

    test 'share project with group' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end

      assert_enqueued_emails 4
      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                     args: [user_emails, group, namespace, locale]
        end

        manager_emails = Member.manager_emails(namespace, locale)
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                   args: [manager_emails, group, namespace, locale]
      end
    end

    test 'share project with group with incorrect permissions' do
      user = users(:ryan_doe)
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        GroupLinks::GroupLinkService.new(user, namespace, params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :link_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.link_namespace_with_group?',
                          name: namespace.name),
                   exception.result.message
      assert_no_enqueued_emails
    end

    test 'share project with group where invalid group id' do
      group_id = 1
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id:, group_access_level: Member::AccessLevel::ANALYST }

      assert_no_difference ['NamespaceGroupLink.count'] do
        GroupLinks::GroupLinkService.new(@user, namespace, params).execute
      end
      assert_no_enqueued_emails
    end

    test 'valid authorization to share project with group' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      assert_authorized_to(:link_namespace_with_group?, namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        GroupLinks::GroupLinkService.new(@user, namespace,
                                         params).execute
      end

      assert_enqueued_emails 4
      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                     args: [user_emails, group, namespace, locale]
        end

        manager_emails = Member.manager_emails(namespace, locale)
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                   args: [manager_emails, group, namespace, locale]
      end
    end

    test 'project shared with group is logged using logidze' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)
      params = { group_id: group.id, group_access_level: Member::AccessLevel::ANALYST }

      project_group_link = GroupLinks::GroupLinkService.new(@user, namespace,
                                                            params).execute
      project_group_link.create_logidze_snapshot!

      assert_equal 1, project_group_link.log_data.version
      assert_equal 1, project_group_link.log_data.size

      assert_equal group.id, project_group_link.at(version: 1).group.id
      assert_equal namespace.id, project_group_link.at(version: 1).namespace.id
      assert_equal Member::AccessLevel::ANALYST, project_group_link.at(version: 1).group_access_level
    end
  end
end
