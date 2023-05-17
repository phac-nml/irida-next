# frozen_string_literal: true

require 'test_helper'

module Members
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
      @project_namespace = @project.namespace
      @group = groups(:group_one)
      @group_member = members(:group_one_member_joan_doe)
      @project_member = members(:project_two_member_james_doe)
    end

    test 'remove group member with correct permissions' do
      assert_difference -> { Member.count } => -1 do
        Members::DestroyService.new(@group_member, @group, @user).execute
      end
    end

    test 'remove group member with incorrect permissions' do
      user = users(:joan_doe)
      assert_no_difference ['Member.count'] do
        Members::DestroyService.new(@group_member, @group, user).execute
      end
      assert @group_member.errors.full_messages.any? do |error_message|
        error_message.include?(I18n.t('services.members.destroy.cannot_remove_self',
                                      namespace_type: @group.type))
      end
    end

    test 'remove group member when user does not have direct or inherited membership' do
      user = users(:david_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Members::DestroyService.new(@group_member, @group, user).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'remove group member with OWNER role when the current user only has the Maintainer role' do
      group_member = members(:group_one_member_james_doe)
      user = users(:joan_doe)

      assert_no_difference ['Member.count'] do
        Members::DestroyService.new(group_member, @group, user).execute
      end

      assert group_member.errors.full_messages.include?(I18n.t('services.members.destroy.role_not_allowed'))
    end

    test 'remove project member with correct permissions' do
      assert_difference -> { Member.count } => -1 do
        Members::DestroyService.new(@project_member, @project_namespace, @user).execute
      end
    end

    test 'remove project member with incorrect permissions' do
      user = users(:joan_doe)
      assert_no_difference ['Member.count'] do
        Members::DestroyService.new(@project_member, @project.namespace, user).execute
      end
      assert @project_member.errors.full_messages.any? do |error_message|
        error_message.include?(I18n.t('services.members.destroy.cannot_remove_self',
                                      namespace_type: @project.namespace.type))
      end
    end

    test 'remove project member with OWNER role when the current user only has the Maintainer role' do
      project = projects(:project1)
      project_namespace = project.namespace
      project_member = members(:project_one_member_john_doe)
      user = users(:joan_doe)

      assert_no_difference ['Member.count'] do
        Members::DestroyService.new(project_member, project_namespace, user).execute
      end

      assert project_member.errors.full_messages.include?(I18n.t('services.members.destroy.role_not_allowed'))
    end

    test 'remove project member when user does not have direct or inherited membership' do
      user = users(:david_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Members::DestroyService.new(@project_member, @project_namespace, user).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end
  end
end
