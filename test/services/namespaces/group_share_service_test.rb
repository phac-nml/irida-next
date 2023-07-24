# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class GroupShareServiceTest < ActiveSupport::TestCase
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

    test 'share group b with group a where n invalid namespace id' do
      group_id = 1
      namespace = groups(:group_one)

      assert_no_difference ['NamespaceGroupLink.count'] do
        Namespaces::GroupShareService.new(@user, group_id, namespace, Member::AccessLevel::ANALYST).execute
      end
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
  end
end
