# frozen_string_literal: true

require 'test_helper'

class GroupPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @policy = GroupPolicy.new(@group, user: @user)
  end

  test '#read?' do
    assert @policy.apply(:read?)
  end

  test '#new?' do
    assert @policy.apply(:new?)
  end

  test '#edit?' do
    assert @policy.apply(:edit?)
  end

  test '#create?' do
    assert @policy.apply(:create?)
  end

  test '#update?' do
    assert @policy.apply(:update?)
  end

  test '#destroy?' do
    assert @policy.apply(:destroy?)
  end

  test '#create_subgroup?' do
    assert @policy.apply(:create_subgroup?)
  end

  test '#transfer?' do
    assert @policy.apply(:transfer?)
  end

  test '#transfer_into_namespace?' do
    assert @policy.apply(:transfer_into_namespace?)
  end

  test '#create_member?' do
    assert @policy.apply(:create_member?)
  end

  test '#update_member?' do
    assert @policy.apply(:update_member?)
  end

  test '#destroy_member?' do
    assert @policy.apply(:destroy_member?)
  end

  test '#member_listing?' do
    assert @policy.apply(:member_listing?)
  end

  test '#sample_listing?' do
    assert @policy.apply(:sample_listing?)
  end

  test '#link_namespace_with_group?' do
    assert @policy.apply(:link_namespace_with_group?)
  end

  test '#unlink_namespace_with_group?' do
    assert @policy.apply(:unlink_namespace_with_group?)
  end

  test '#update_namespace_with_group_link?' do
    assert @policy.apply(:update_namespace_with_group_link?)
  end

  test '#submit_workflow?' do
    assert @policy.apply(:submit_workflow?)
  end

  test '#view_workflow_executions?' do
    assert @policy.apply(:view_workflow_executions?)
  end

  test '#update_sample_metadata?' do
    assert @policy.apply(:update_sample_metadata?)
  end

  test '#import_samples_and_metadata?' do
    assert @policy.apply(:import_samples_and_metadata?)
  end

  test '#view_attachments?' do
    assert @policy.apply(:view_attachments?)
  end

  test '#create_attachment?' do
    assert @policy.apply(:create_attachment?)
  end

  test '#destroy_attachment?' do
    assert @policy.apply(:destroy_attachment?)
  end

  test '#create_metadata_templates?' do
    assert @policy.apply(:create_metadata_templates?)
  end

  test '#destroy_metadata_templates?' do
    assert @policy.apply(:destroy_metadata_templates?)
  end

  test '#update_metadata_templates?' do
    assert @policy.apply(:update_metadata_templates?)
  end

  test '#view_metadata_templates?' do
    assert @policy.apply(:view_metadata_templates?)
  end

  test 'scope' do
    scoped_groups = @policy.apply_scope(Group, type: :relation)

    # John Doe has access to 28 groups
    assert_equal 33, scoped_groups.count

    user = users(:david_doe)
    policy = GroupPolicy.new(user:)
    scoped_groups = policy.apply_scope(Group, type: :relation)
    # David Doe has access to 2 groups
    assert_equal 12, scoped_groups.count
  end

  test 'scope with expired group member' do
    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save

    scoped_groups = @policy.apply_scope(Group, type: :relation)

    assert_equal 31, scoped_groups.count
    scoped_groups_names = scoped_groups.pluck(:name)
    assert_not scoped_groups_names.include?(groups(:group_one).name)
    assert_not scoped_groups_names.include?(groups(:david_doe_group_four).name)

    linked_group_member = members(:namespace_group_link8_member1)
    linked_group_member.expires_at = 10.days.ago.to_date
    linked_group_member.save

    scoped_groups = @policy.apply_scope(Group, type: :relation)

    assert_equal 30, scoped_groups.count
    scoped_groups_names = scoped_groups.pluck(:name)
    assert_not scoped_groups_names.include?(groups(:namespace_group_link_group_one).name)
  end
end
