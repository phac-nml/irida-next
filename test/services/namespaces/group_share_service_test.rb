# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class GroupShareServiceTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
    def setup
      @user = users(:john_doe)
    end

    test 'share group b with group a' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        Namespaces::GroupShareService.new(@user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'share group b with group a with incorrect permissions' do
      user = users(:ryan_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Namespaces::GroupShareService.new(user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :share_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.share_namespace_with_group?', name: namespace.name),
                   exception.result.message
    end

    test 'share group b with group a where invalid group id' do
      group_id = 1
      namespace = groups(:group_one)

      assert_no_difference ['NamespaceGroupLink.count'] do
        Namespaces::GroupShareService.new(@user, group_id, namespace, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'should not be able to share user namespace with group' do
      user = users(:david_doe)
      group = groups(:group_one)
      namespace = namespaces_user_namespaces(:david_doe_namespace)

      assert_no_difference ['NamespaceGroupLink.count'] do
        Namespaces::GroupShareService.new(user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert namespace.errors.full_messages.include?(I18n.t('services.groups.share.invalid_namespace_type'))
    end

    test 'valid authorization to share group with other groups' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      assert_authorized_to(:share_namespace_with_group?, namespace,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Namespaces::GroupShareService.new(@user, group.id, namespace,
                                          Member::AccessLevel::ANALYST).execute
      end
    end

    test 'group a shared with group b is logged using logidze' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      group_group_link = Namespaces::GroupShareService.new(@user, group.id, namespace,
                                                           Member::AccessLevel::ANALYST).execute
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

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        Namespaces::GroupShareService.new(@user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'share project with group with incorrect permissions' do
      user = users(:ryan_doe)
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Namespaces::GroupShareService.new(user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert_equal ProjectNamespacePolicy, exception.policy
      assert_equal :share_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.share_namespace_with_group?',
                          name: namespace.name),
                   exception.result.message
    end

    test 'share project with group where invalid group id' do
      group_id = 1
      namespace = namespaces_project_namespaces(:project22_namespace)

      assert_no_difference ['NamespaceGroupLink.count'] do
        Namespaces::GroupShareService.new(@user, group_id, namespace, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'valid authorization to share project with group' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)

      assert_authorized_to(:share_namespace_with_group?, namespace,
                           with: ProjectNamespacePolicy,
                           context: { user: @user }) do
        Namespaces::GroupShareService.new(@user, group.id, namespace,
                                          Member::AccessLevel::ANALYST).execute
      end
    end

    test 'project shared with group is logged using logidze' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)

      project_group_link = Namespaces::GroupShareService.new(@user, group.id, namespace,
                                                             Member::AccessLevel::ANALYST).execute
      project_group_link.create_logidze_snapshot!

      assert_equal 1, project_group_link.log_data.version
      assert_equal 1, project_group_link.log_data.size

      assert_equal group.id, project_group_link.at(version: 1).group.id
      assert_equal namespace.id, project_group_link.at(version: 1).namespace.id
      assert_equal Member::AccessLevel::ANALYST, project_group_link.at(version: 1).group_access_level
    end
  end
end
