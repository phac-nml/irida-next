# frozen_string_literal: true

require 'test_helper'

class UpdateMembershipsJobTest < ActiveJob::TestCase
  def setup
    @user = users(:john_doe)
    @group_member = members(:group_one_member_ryan_doe)
    @first_subgroup_member = members(:subgroup1_member_ryan_doe)
    @second_subgroup_member = members(:subgroup2_member_ryan_doe)
    @project_member = members(:project_one_member_ryan_doe)
  end

  test 'parent group access level higher' do
    perform_enqueued_jobs do
      assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.access_level
      assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::MAINTAINER }
      Members::UpdateService.new(@group_member, @group_member.namespace, @user, valid_params).execute

      assert_equal Member::AccessLevel::MAINTAINER, @group_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @project_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
    end
  end

  test 'subgroup access level higher' do
    perform_enqueued_jobs do
      assert_equal Member::AccessLevel::GUEST, @group_member.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.access_level
      assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

      valid_params = { user: @first_subgroup_member.user, access_level: Member::AccessLevel::MAINTAINER }
      Members::UpdateService.new(@first_subgroup_member, @group_member.namespace, @user, valid_params).execute

      assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
    end
  end

  test 'nested subgroup access level higher' do
    perform_enqueued_jobs do
      assert_equal Member::AccessLevel::GUEST, @group_member.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.access_level
      assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level

      valid_params = { user: @second_subgroup_member.user, access_level: Member::AccessLevel::MAINTAINER }
      Members::UpdateService.new(@second_subgroup_member, @group_member.namespace, @user, valid_params).execute

      assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.reload.access_level
      assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
    end
  end

  test 'project access level higher' do
    perform_enqueued_jobs do
      assert_equal Member::AccessLevel::GUEST, @group_member.access_level
      assert_equal Member::AccessLevel::GUEST, @project_member.access_level
      assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
      assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

      valid_params = { user: @project_member.user, access_level: Member::AccessLevel::MAINTAINER }
      Members::UpdateService.new(@project_member, @group_member.namespace, @user, valid_params).execute

      assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
      assert_equal Member::AccessLevel::MAINTAINER, @project_member.reload.access_level
      assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
      assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
    end
  end

  test 'empty memberships' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @project_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @project_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'memberships do not exist' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @project_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([0])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @project_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'maximum nested memberships' do
    perform_enqueued_jobs do
      (Namespace::MAX_ANCESTORS - 2).times do |n|
        assert_equal Member::AccessLevel::GUEST,
                     groups("subgroup#{n + 1}").group_members.where(user_id: @group_member.user_id).first.access_level
      end

      valid_params = { user: @group_member.user, access_level: Member::AccessLevel::MAINTAINER }
      Members::UpdateService.new(@group_member, @group_member.namespace, @user, valid_params).execute

      (Namespace::MAX_ANCESTORS - 2).times do |n|
        assert_equal Member::AccessLevel::MAINTAINER,
                     groups("subgroup#{n + 1}").group_members.where(user_id: @group_member.user_id).first.access_level
      end
    end
  end

  test 'nested memberships' do
    group_member1 = members(:group_nine_member_james_doe)
    group_member2 = members(:subgroup_one_group_nine_member_james_doe)
    group_member3 = members(:group_ten_member_james_doe)

    assert_equal Member::AccessLevel::MAINTAINER,
                 group_member1.access_level
    assert_equal Member::AccessLevel::OWNER,
                 group_member2.access_level
    assert_equal Member::AccessLevel::GUEST,
                 group_member3.access_level

    UpdateMembershipsJob.perform_now([group_member1.id, group_member2.id])

    assert_equal Member::AccessLevel::MAINTAINER,
                 group_member1.reload.access_level
    assert_equal Member::AccessLevel::OWNER,
                 group_member2.reload.access_level
    assert_equal Member::AccessLevel::OWNER,
                 group_member3.reload.access_level
  end
end
