# frozen_string_literal: true

require 'test_helper'

class GroupPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @policy = GroupPolicy.new(@group, user: @user)
  end

  test '#read?' do
    assert @policy.read?
  end

  test '#new?' do
    assert @policy.new?
  end

  test '#edit?' do
    assert @policy.edit?
  end

  test '#create?' do
    assert @policy.create?
  end

  test '#update?' do
    assert @policy.update?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end

  test '#create_subgroup?' do
    assert @policy.create_subgroup?
  end

  test '#transfer?' do
    assert @policy.transfer?
  end

  test '#transfer_into_namespace?' do
    assert @policy.transfer_into_namespace?
  end

  test '#create_member?' do
    assert @policy.create_member?
  end

  test '#update_member?' do
    assert @policy.update_member?
  end

  test '#destroy_member?' do
    assert @policy.destroy_member?
  end

  test '#member_listing?' do
    assert @policy.member_listing?
  end

  test '#sample_listing?' do
    assert @policy.sample_listing?
  end

  test '#link_namespace_with_group?' do
    assert @policy.link_namespace_with_group?
  end

  test '#unlink_namespace_with_group?' do
    assert @policy.unlink_namespace_with_group?
  end

  test '#update_namespace_with_group_link?' do
    assert @policy.update_namespace_with_group_link?
  end

  test 'scope' do
    scoped_groups = @policy.apply_scope(Group, type: :relation)

    # John Doe has access to 28 groups
    assert_equal 30, scoped_groups.count

    user = users(:david_doe)
    policy = GroupPolicy.new(user:)
    scoped_groups = policy.apply_scope(Group, type: :relation)
    # David Doe has access to 2 groups
    assert_equal 2, scoped_groups.count
  end

  test 'scope with expired group member' do
    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save

    scoped_groups = @policy.apply_scope(Group, type: :relation)

    assert_equal 25, scoped_groups.count
    scoped_groups_names = scoped_groups.pluck(:name)
    assert_not scoped_groups_names.include?(groups(:group_one).name)
    assert_not scoped_groups_names.include?(groups(:subgroup3).name)
    assert_not scoped_groups_names.include?(groups(:subgroup4).name)
    assert_not scoped_groups_names.include?(groups(:subgroup5).name)
    assert_not scoped_groups_names.include?(groups(:david_doe_group_four).name)

    linked_group_member = members(:namespace_group_link8_member1)
    linked_group_member.expires_at = 10.days.ago.to_date
    linked_group_member.save

    scoped_groups = @policy.apply_scope(Group, type: :relation)

    assert_equal 24, scoped_groups.count
    scoped_groups_names = scoped_groups.pluck(:name)
    assert_not scoped_groups_names.include?(groups(:namespace_group_link_group_one).name)
  end
end
