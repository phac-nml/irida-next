# frozen_string_literal: true

require 'test_helper'

module Members
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
      @project_namespace = @project.namespace
      @group = groups(:group_one)
      @group_member = members_group_members(:group_one_member_joan_doe)
      @project_member = members_project_members(:project_two_member_james_doe)
    end

    test 'remove group member with correct permissions' do
      assert_difference -> { Members::GroupMember.count } => -1 do
        Members::DestroyService.new(@group_member, @group, @user).execute
      end
    end

    test 'remove group member with incorrect permissions' do
      user = users(:joan_doe)
      assert_no_difference ['Members::GroupMember.count'] do
        Members::DestroyService.new(@group_member, @group, user).execute
      end
      assert @group_member.errors.full_messages.any? do |error_message|
        error_message.include?(I18n.t('services.members.destroy.cannot_remove_self',
                                      namespace_type: @group.type))
      end
    end

    test 'remove project member with correct permissions' do
      assert_difference -> { Members::ProjectMember.count } => -1 do
        Members::DestroyService.new(@project_member, @project_namespace, @user).execute
      end
    end

    test 'remove project member with incorrect permissions' do
      user = users(:joan_doe)
      assert_no_difference ['Members::ProjectMember.count'] do
        Members::DestroyService.new(@project_member, @project.namespace, user).execute
      end
      assert @project_member.errors.full_messages.any? do |error_message|
        error_message.include?(I18n.t('services.members.destroy.cannot_remove_self',
                                      namespace_type: @project.namespace.type))
      end
    end
  end
end
