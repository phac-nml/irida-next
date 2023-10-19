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

    # John Doe has access to 19 groups
    assert_equal scoped_groups.count, 20

    user = users(:david_doe)
    policy = GroupPolicy.new(user:)
    scoped_groups = policy.apply_scope(Group, type: :relation)
    # David Doe has access to 1 group
    assert_equal scoped_groups.count, 1
  end
end
