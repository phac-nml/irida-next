# frozen_string_literal: true

require 'test_helper'

module Members
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
      @project_namespace = @project.namespace
      @group = groups(:group_one)
      @group_member = members(:group_one_member_joan_doe)
      @project_member = members(:project_two_member_joan_doe)
    end

    test 'update group member with valid params' do
      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }

      assert_equal @group_member.access_level, Member::AccessLevel::MAINTAINER

      assert_changes -> { @group_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@group_member, @group, @user, valid_params).execute
      end
    end

    test 'update group member with invalid params' do
      invalid_params = { user: @group_member.user, access_level: 1000 }

      assert_no_changes -> { @group_member } do
        Members::UpdateService.new(@group_member, @group, @user, invalid_params).execute
      end

      assert @group_member.errors[:access_level].include?(
        I18n.t('activerecord.errors.models.member.attributes.access_level.inclusion')
      )
    end

    test 'update your own group membership' do
      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }
      user = users(:joan_doe)

      assert_no_changes -> { @group_member } do
        Members::UpdateService.new(@group_member, @group, user, valid_params).execute
      end

      assert @group_member.errors.full_messages.include?(I18n.t('services.members.update.cannot_update_self',
                                                                namespace_type: @group.class.model_name.human))
    end

    test 'update group member with incorrect permissions' do
      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) do
        Members::UpdateService.new(@group_member, @group, user, valid_params).execute
      end
    end

    test 'update project member with valid params' do
      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }

      assert_equal @project_member.access_level, Member::AccessLevel::MAINTAINER

      assert_changes -> { @project_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@project_member, @project_namespace, @user, valid_params).execute
      end
    end

    test 'update project member with invalid params' do
      invalid_params = { user: @project_member.user, access_level: 1000 }

      assert_no_changes -> { @project_member } do
        Members::UpdateService.new(@project_member, @project_namespace, @user, invalid_params).execute
      end

      assert @project_member.errors[:access_level].include?(
        I18n.t('activerecord.errors.models.member.attributes.access_level.inclusion')
      )
    end

    test 'update your own project membership' do
      user = users(:joan_doe)
      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }

      assert_no_changes -> { @project_member } do
        Members::UpdateService.new(@project_member, @project_namespace, user, valid_params).execute
      end

      assert @project_member.errors.full_messages.include?(
        I18n.t('services.members.update.cannot_update_self',
               namespace_type: @project_namespace.class.model_name.human)
      )
    end

    test 'update project member with incorrect permissions' do
      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) do
        Members::UpdateService.new(@project_member, @project_namespace, user, valid_params).execute
      end
    end
  end
end
