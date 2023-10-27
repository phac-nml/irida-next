# frozen_string_literal: true

require 'test_helper'

class UpdateMembershipsJobTest < ActiveJob::TestCase
  def setup
    Member.skip_callback(:update, :after, :update_descendant_memberships)
    @group_member = members(:group_one_member_ryan_doe)
    @first_subgroup_member = members(:subgroup1_member_ryan_doe)
    @second_subgroup_member = members(:subgroup2_member_ryan_doe)
  end

  def teardown
    Member.set_callback(:update, :after, :update_descendant_memberships)
  end

  test 'parent group access level higher' do
    @group_member.access_level = Member::AccessLevel::MAINTAINER
    @group_member.save

    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@group_member.id])

    assert_equal Member::AccessLevel::MAINTAINER, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'subgroup access level higher' do
    @first_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @first_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@first_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'nested subgroup access level higher' do
    @second_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @second_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@second_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'empty memberships' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'memberships do not exist' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([0])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'maximum nested memberships' do
    @group_member.access_level = Member::AccessLevel::MAINTAINER
    @group_member.save

    (Namespace::MAX_ANCESTORS - 1).times do |n|
      assert_equal Member::AccessLevel::GUEST,
                   groups("subgroup#{n + 1}").group_members.where(user_id: @group_member.user_id).first.access_level
    end

    UpdateMembershipsJob.perform_now([@group_member.id])

    (Namespace::MAX_ANCESTORS - 1).times do |n|
      assert_equal Member::AccessLevel::MAINTAINER,
                   groups("subgroup#{n + 1}").group_members.where(user_id: @group_member.user_id).first.access_level
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
