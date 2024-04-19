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

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Members::UpdateService.new(@group_member, @group, user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :update_member?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'update group member to OWNER role when the current user only has the Maintainer role' do
      group_member = members(:group_one_member_ryan_doe)
      valid_params = { user: group_member.user, access_level: Member::AccessLevel::OWNER }
      user = users(:joan_doe)

      assert_no_changes -> { group_member } do
        Members::UpdateService.new(group_member, @group, user, valid_params).execute
      end

      assert group_member.errors.full_messages.include?(I18n.t('services.members.update.role_not_allowed'))
    end

    test 'update group member to role lower than owner when they have owner role in the parent group' do
      group = groups(:group_five)
      group_member = members(:subgroup_one_group_five_member_james_doe)
      valid_params = { user: group_member.user, access_level: Member::AccessLevel::ANALYST }

      assert_no_changes -> { group_member } do
        Members::UpdateService.new(group_member, group, @user, valid_params).execute
      end

      assert_not_equal Member.find_by(user_id: group_member.user_id,
                                      namespace_id: group_member.namespace_id).access_level,
                       Member::AccessLevel::ANALYST
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

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Members::UpdateService.new(@project_member, @project_namespace, user, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :update_member?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'update project member to OWNER role when the current user only has the Maintainer role' do
      project = projects(:project1)
      project_namespace = project.namespace
      project_member = members(:project_one_member_ryan_doe)
      valid_params = { user: project_member.user, access_level: Member::AccessLevel::OWNER }
      user = users(:joan_doe)

      assert_no_changes -> { project_member } do
        Members::UpdateService.new(project_member, project_namespace, user, valid_params).execute
      end

      assert project_member.errors.full_messages.include?(I18n.t('services.members.update.role_not_allowed'))
    end

    test 'update project member to role lower than owner when they have owner role in the parent group' do
      project = projects(:project22)
      project_namespace = project.namespace
      project_member = members(:project_twenty_two_member_james_doe)
      valid_params = { user: project_member.user, access_level: Member::AccessLevel::ANALYST }

      assert_no_changes -> { project_member } do
        Members::UpdateService.new(project_member, project_namespace, @user, valid_params).execute
      end

      assert_not_equal Member.find_by(user_id: project_member.user_id,
                                      namespace_id: project_member.namespace_id).access_level,
                       Member::AccessLevel::ANALYST
    end

    test 'valid authorization to update group member' do
      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }

      assert_authorized_to(:update_member?, @group, with: GroupPolicy,
                                                    context: { user: @user }) do
        Members::UpdateService.new(@group_member, @group, @user, valid_params).execute
      end
    end

    test 'valid authorization to update project member' do
      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }

      assert_authorized_to(:update_member?, @project_namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Members::UpdateService.new(@project_member,
                                   @project_namespace, @user, valid_params).execute
      end
    end

    test 'update access level of group member to a higher level than they have in a project' do
      group = groups(:group_six)
      group_member = members(:group_six_member_james_doe)
      project_member = members(:project_twenty_three_member_james_doe)

      valid_params = { user: group_member.user, access_level: Member::AccessLevel::MAINTAINER }

      assert_equal group_member.access_level, Member::AccessLevel::GUEST
      assert_equal project_member.access_level, Member::AccessLevel::GUEST

      assert_changes -> { group_member.access_level }, to: Member::AccessLevel::MAINTAINER do
        Members::UpdateService.new(group_member, group, @user, valid_params).execute
      end
      perform_enqueued_jobs

      # group member is also a member of a descendant of the group so their access level is updated
      # to the same access level for the project membership
      assert_equal Member::AccessLevel::MAINTAINER, Member.find_by(id: project_member.id).access_level
    end

    test 'group member update changes logged using logidze' do
      @group_member.create_logidze_snapshot!

      assert_equal 1, @group_member.log_data.version
      assert_equal 1, @group_member.log_data.size

      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }

      assert_changes -> { @group_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@group_member, @group, @user, valid_params).execute
      end

      @group_member.create_logidze_snapshot!

      assert_equal 2, @group_member.log_data.version
      assert_equal 2, @group_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @group_member.at(version: 1).access_level

      assert_equal Member::AccessLevel::OWNER, @group_member.at(version: 2).access_level
    end

    test 'group member update changes logged using logidze switch version' do
      @group_member.create_logidze_snapshot!

      assert_equal 1, @group_member.log_data.version
      assert_equal 1, @group_member.log_data.size

      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::OWNER }

      assert_changes -> { @group_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@group_member, @group, @user, valid_params).execute
      end

      @group_member.create_logidze_snapshot!

      assert_equal 2, @group_member.log_data.version
      assert_equal 2, @group_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @group_member.at(version: 1).access_level

      assert_equal Member::AccessLevel::OWNER, @group_member.at(version: 2).access_level

      @group_member.switch_to!(1)

      assert_equal 1, @group_member.log_data.version
      assert_equal 2, @group_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @group_member.access_level
    end

    test 'project member update changes logged using logidze' do
      @project_member.create_logidze_snapshot!

      assert_equal 1, @project_member.log_data.version
      assert_equal 1, @project_member.log_data.size

      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }

      assert_changes -> { @project_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@project_member, @project_namespace, @user, valid_params).execute
      end

      @project_member.create_logidze_snapshot!

      assert_equal 2, @project_member.log_data.version
      assert_equal 2, @project_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @project_member.at(version: 1).access_level

      assert_equal Member::AccessLevel::OWNER, @project_member.at(version: 2).access_level
    end

    test 'project member update changes logged using logidze switch version' do
      @project_member.create_logidze_snapshot!

      assert_equal 1, @project_member.log_data.version
      assert_equal 1, @project_member.log_data.size

      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::OWNER }

      assert_changes -> { @project_member.access_level }, to: Member::AccessLevel::OWNER do
        Members::UpdateService.new(@project_member, @project_namespace, @user, valid_params).execute
      end

      @project_member.create_logidze_snapshot!

      assert_equal 2, @project_member.log_data.version
      assert_equal 2, @project_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @project_member.at(version: 1).access_level

      assert_equal Member::AccessLevel::OWNER, @project_member.at(version: 2).access_level

      @project_member.switch_to!(1)

      assert_equal 1, @project_member.log_data.version
      assert_equal 2, @project_member.log_data.size

      assert_equal Member::AccessLevel::MAINTAINER, @project_member.access_level
    end
  end
end
