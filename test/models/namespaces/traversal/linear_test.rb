# frozen_string_literal: true

require 'test_helper'

module Namespaces
  module Traversal
    class LinearTest < ActiveSupport::TestCase
      test '#linear_self_and_ancestors when collection is empty' do
        assert_equal [], Namespace.none.linear_self_and_ancestors
      end

      test '#linear_self_and_ancestors when collection is non empty' do
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = Group.where(id: subgroup.id).linear_self_and_ancestors

        assert_equal [group.id, subgroup.id].sort, result.pluck(:id).sort
      end

      test '#linear_self_and_ancestors includes ancestors of a different STI type than the receiver' do
        project = namespaces_project_namespaces(:project4_namespace)
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = Namespaces::ProjectNamespace.where(id: project.id).linear_self_and_ancestors

        assert_equal [group.id, subgroup.id, project.id].sort, result.pluck(:id).sort
      end

      test '#linear_ancestors excludes self' do
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        assert_equal [group.id], subgroup.linear_ancestors.pluck(:id)
      end

      test '#linear_ancestors on a root namespace is empty' do
        assert_equal [], groups(:group_three).linear_ancestors.pluck(:id)
      end

      test '#linear_self_and_descendants when collection is empty' do
        assert_equal [], Namespace.none.linear_self_and_descendants
      end

      test '#linear_self_and_descendants includes descendants of a different STI type than the receiver' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        result = Group.where(id: group.id).linear_self_and_descendants

        assert_equal [group.id, subgroup.id, project.id].sort, result.pluck(:id).sort
      end

      test '#linear_descendants excludes self' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        assert_equal [subgroup.id, project.id].sort, group.linear_descendants.pluck(:id).sort
      end

      test '#linear_self_and_ancestors_of_type filters ancestors by STI type' do
        project = namespaces_project_namespaces(:project4_namespace)
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = project.linear_self_and_ancestors_of_type(Group.sti_name)

        assert_equal [group.id, subgroup.id].sort, result.pluck(:id).sort
      end

      test '#linear_self_and_descendants_of_type filters descendants by STI type' do
        group = groups(:group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        result = group.linear_self_and_descendants_of_type(Namespaces::ProjectNamespace.sti_name)

        assert_equal [project.id], result.pluck(:id)
      end

      test '#linear_without_descendants when collection has related items' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        result = Group.where(id: [group.id, subgroup.id]).linear_without_descendants

        assert_equal [group.id], result.pluck(:id)
      end

      test '#linear_without_descendants when collection has no related items' do
        group_two = groups(:group_two)
        group_three = groups(:group_three)

        result = Group.where(id: [group_two.id, group_three.id]).linear_without_descendants

        assert_equal [group_two.id, group_three.id].sort, result.pluck(:id).sort
      end

      test 'bare traversal methods remain route-based and are unaffected by Linear being included' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        assert_equal [subgroup.id], group.descendants.pluck(:id)
        assert_equal [group.id], subgroup.ancestors.pluck(:id)
      end

      test 'write_traversal_ids sets traversal_ids on create' do
        parent = groups(:group_one)

        new_group = Group.create!(name: 'Linear Traversal Test Group', path: 'linear-traversal-test-group', parent:)

        assert_equal parent.traversal_ids + [new_group.id], new_group.traversal_ids
      end

      test 'write_traversal_ids sets traversal_ids to just self for a new root namespace' do
        new_group = Group.create!(name: 'Linear Traversal Root Test Group', path: 'linear-traversal-root-test-group')

        assert_equal [new_group.id], new_group.traversal_ids
      end

      test 'sync_traversal_ids updates traversal_ids for the namespace and all of its descendants on reparent' do
        new_root = Group.create!(name: 'Linear Traversal New Root', path: 'linear-traversal-new-root')
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        subgroup.update!(parent: new_root)
        subgroup.reload
        project.reload

        assert_equal [new_root.id, subgroup.id], subgroup.traversal_ids
        assert_equal [new_root.id, subgroup.id, project.id], project.traversal_ids
      end

      test 'sync_traversal_ids is a no-op when parent_id does not change' do
        subgroup = groups(:subgroup_one_group_three)
        original_traversal_ids = subgroup.traversal_ids

        subgroup.update!(description: 'updated description')

        assert_equal original_traversal_ids, subgroup.reload.traversal_ids
      end
    end
  end
end
