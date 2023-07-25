# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class GroupUnshareServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'unshare group b with group a' do
      group = groups(:group_three)
      namespace = groups(:subgroup1)

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end

    test 'share group b with group a then unshare' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        Namespaces::GroupShareService.new(@user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end

    test 'unshare group b with group a with invalid permissions' do
      user = users(:ryan_doe)
      group = groups(:group_three)
      namespace = groups(:subgroup1)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Namespaces::GroupUnshareService.new(user, group.id, namespace).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :unshare_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.unshare_namespace_with_group?', name: namespace.name),
                   exception.result.message
    end

    test 'unshare groub b with group a when no link exists' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute

      assert namespace.errors.full_messages.include?('Namespace to group link does not exist')
    end

    test 'valid authorization to unshare group' do
      group = groups(:group_three)
      namespace = groups(:subgroup1)

      assert_authorized_to(:unshare_namespace_with_group?, namespace,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end

    test 'unshare project with group' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, namespace_group_link.group.id,
                                            namespace_group_link.namespace).execute
      end
    end

    test 'share project with group then unshare' do
      group = groups(:group_one)
      namespace = namespaces_project_namespaces(:project22_namespace)

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        Namespaces::GroupShareService.new(@user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end

    test 'unshare project with group with invalid permissions' do
      user = users(:ryan_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Namespaces::GroupUnshareService.new(user, namespace_group_link.group.id, namespace_group_link.namespace).execute
      end

      assert_equal ProjectNamespacePolicy, exception.policy
      assert_equal :unshare_namespace_with_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.unshare_namespace_with_group?',
                          name: namespace_group_link.namespace.name),
                   exception.result.message
    end

    test 'valid authorization to unshare project' do
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      assert_authorized_to(:unshare_namespace_with_group?, namespace_group_link.namespace,
                           with: ProjectNamespacePolicy,
                           context: { user: @user }) do
        Namespaces::GroupUnshareService.new(@user, namespace_group_link.group.id,
                                            namespace_group_link.namespace).execute
      end
    end
  end
end
