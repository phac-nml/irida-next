# frozen_string_literal: true

require 'test_helper'

class UpdateMembershipsJobTest < ActiveJob::TestCase
  def setup
    @group_member = members(:group_one_member_ryan_doe)
    @first_subgroup_member = members(:subgroup1_member_ryan_doe)
    @second_subgroup_member = members(:subgroup2_member_ryan_doe)
  end

  test 'equal access levels when parent group membership passed' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@group_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'equal access levels when subgroup membership passed' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@first_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'equal access levels when nested subgroup membership passed' do
    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@second_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.reload.access_level
  end

  test 'parent group access level higher when parent group membership passed' do
    @group_member.access_level = Member::AccessLevel::MAINTAINER
    @group_member.save

    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@group_member.id])

    assert_equal Member::AccessLevel::MAINTAINER, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'parent group access level higher when subgroup group membership passed' do
    @group_member.access_level = Member::AccessLevel::MAINTAINER
    @group_member.save

    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@first_subgroup_member.id])

    assert_equal Member::AccessLevel::MAINTAINER, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'parent group access level higher when nested subgroup group membership passed' do
    @group_member.access_level = Member::AccessLevel::MAINTAINER
    @group_member.save

    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@second_subgroup_member.id])

    assert_equal Member::AccessLevel::MAINTAINER, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'subgroup access level higher when parent group membership passed' do
    @first_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @first_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@group_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'subgroup access level higher when subgroup group membership passed' do
    @first_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @first_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@first_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'subgroup access level higher when nested subgroup group membership passed' do
    @first_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @first_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @second_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@second_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'nested subgroup access level higher when parent group membership passed' do
    @second_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @second_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@group_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'nested subgroup access level higher when subgroup group membership passed' do
    @second_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @second_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@first_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end

  test 'nested subgroup access level higher when nested subgroup group membership passed' do
    @second_subgroup_member.access_level = Member::AccessLevel::MAINTAINER
    @second_subgroup_member.save

    assert_equal Member::AccessLevel::GUEST, @group_member.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.access_level

    UpdateMembershipsJob.perform_now([@second_subgroup_member.id])

    assert_equal Member::AccessLevel::GUEST, @group_member.reload.access_level
    assert_equal Member::AccessLevel::GUEST, @first_subgroup_member.reload.access_level
    assert_equal Member::AccessLevel::MAINTAINER, @second_subgroup_member.reload.access_level
  end
end
