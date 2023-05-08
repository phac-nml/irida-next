# frozen_string_literal: true

require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  def setup
    @group = groups(:group_one)
    @subgroup_one = groups(:subgroup1)
    @group_three = groups(:group_three)
  end

  test 'valid group' do
    assert @group.valid?
  end

  test 'invalid if parent is not a group' do
    @group.parent = namespaces_user_namespaces(:john_doe_namespace)
    assert_not @group.valid?
    assert_not_nil @group.errors[:parent_id]
  end

  test 'invalid if more than 9 ancestors' do
    @subgroup = groups(:subgroup10)
    assert_not @subgroup.valid?, 'subgroup is valid with more than 9 ancestors'
    assert_not_nil @subgroup.errors[:parent_id], 'no validation error for parent'
  end

  test '#ancestors' do
    assert_equal [@group], @subgroup_one.ancestors
  end

  test '#ancestor_ids' do
    assert_equal [@group.id], @subgroup_one.ancestor_ids.pluck(:id)
  end

  test '#self_and_ancestors' do
    assert_includes @subgroup_one.self_and_ancestors, @subgroup_one
    assert_includes @subgroup_one.self_and_ancestors, @group
    assert_equal 2, @subgroup_one.self_and_ancestors.count
  end

  test '#descendants' do
    assert_includes @group_three.descendants, groups(:subgroup_one_group_three)
    assert_equal 1, @group_three.descendants.count
  end

  test '#self_and_descendants' do
    assert_includes @group_three.self_and_descendants, @group_three
    assert_includes @group_three.self_and_descendants, groups(:subgroup_one_group_three)
    assert_equal 2, @group_three.self_and_descendants.count
  end

  test '#human_name' do
    assert_equal @group.route.name, @group.human_name
  end

  test '#group_namespace?' do
    assert @group.group_namespace?
  end

  test '#project_namespace?' do
    assert_not @group.project_namespace?
  end

  test '#user_namespace?' do
    assert_not @group.user_namespace?
  end

  test '#owner_required?' do
    assert_not @group.owner_required?
  end

  test '#validate_type' do
    assert_nil @group.validate_type
  end

  test '#validate_parent_type' do
    assert_nil @group.validate_parent_type
  end

  test '#full_name' do
    assert_equal @group.route.name, @group.full_name
  end

  test '#full_path' do
    assert_equal @group.route.path, @group.full_path
  end
end
