# frozen_string_literal: true

require 'test_helper'

module Namespaces
  module Traversal
    class LinearTest < ActiveSupport::TestCase
      test '#use_traversal_ids? is true when traversal_ids is populated' do
        assert groups(:group_three).use_traversal_ids?
      end

      test '#use_traversal_ids? is false when traversal_ids is blank' do
        group = groups(:group_three)
        group.traversal_ids = []

        assert_not group.use_traversal_ids?
      end

      test '#self_and_ancestors when collection is empty' do
        assert_equal [], Namespace.none.self_and_ancestors
      end

      test '#self_and_ancestors when collection is non empty' do
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = Group.where(id: subgroup.id).self_and_ancestors

        assert_equal [group.id, subgroup.id].sort, result.pluck(:id).sort
      end

      test '#self_and_ancestors (scope) excludes ancestors of a different STI type than the receiver' do
        project = namespaces_project_namespaces(:project4_namespace)

        result = Namespaces::ProjectNamespace.where(id: project.id).self_and_ancestors

        assert_equal [project.id], result.pluck(:id)
      end

      test '#self_and_ancestors_across_types (scope) includes ancestors of a different STI type than the receiver' do
        project = namespaces_project_namespaces(:project4_namespace)
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = Namespaces::ProjectNamespace.where(id: project.id).self_and_ancestors_across_types

        assert_equal [group.id, subgroup.id, project.id].sort, result.pluck(:id).sort
      end

      test '#ancestors excludes self' do
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        assert_equal [group.id], subgroup.ancestors.pluck(:id)
      end

      test '#ancestors on a root namespace is empty' do
        assert_equal [], groups(:group_three).ancestors.pluck(:id)
      end

      test '#self_and_descendants when collection is empty' do
        assert_equal [], Namespace.none.self_and_descendants
      end

      test '#self_and_descendants (scope) excludes descendants of a different STI type than the receiver' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        result = Group.where(id: group.id).self_and_descendants

        assert_equal [group.id, subgroup.id].sort, result.pluck(:id).sort
      end

      test '#self_and_descendants_across_types (scope) includes other-STI-type descendants' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        result = Group.where(id: group.id).self_and_descendants_across_types

        assert_equal [group.id, subgroup.id, project.id].sort, result.pluck(:id).sort
      end

      test '#descendants excludes self' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        assert_equal [subgroup.id], group.descendants.pluck(:id)
      end

      test '#descendants (unlike #self_and_descendants_of_type) excludes namespaces of a different STI type' do
        group = groups(:group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        assert_not_includes group.descendants.pluck(:id), project.id
      end

      test '#self_and_ancestors_of_type filters ancestors by STI type' do
        project = namespaces_project_namespaces(:project4_namespace)
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)

        result = project.self_and_ancestors_of_type(Group.sti_name)

        assert_equal [group.id, subgroup.id].sort, result.pluck(:id).sort
      end

      test '#self_and_descendants_of_type filters descendants by STI type' do
        group = groups(:group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        result = group.self_and_descendants_of_type(Namespaces::ProjectNamespace.sti_name)

        assert_equal [project.id], result.pluck(:id)
      end

      test '#without_descendants when collection has related items' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        result = Group.where(id: [group.id, subgroup.id]).without_descendants

        assert_equal [group.id], result.pluck(:id)
      end

      test '#without_descendants when collection has no related items' do
        group_two = groups(:group_two)
        group_three = groups(:group_three)

        result = Group.where(id: [group_two.id, group_three.id]).without_descendants

        assert_equal [group_two.id, group_three.id].sort, result.pluck(:id).sort
      end

      test 'falls back to route-based ancestors when traversal_ids is blank' do
        subgroup = groups(:subgroup_one_group_three)
        group = groups(:group_three)
        subgroup.traversal_ids = []

        assert_equal [group.id], subgroup.ancestors.pluck(:id)
        assert_equal subgroup.route_based_ancestors.pluck(:id).sort, subgroup.ancestors.pluck(:id).sort
      end

      test 'falls back to route-based descendants when traversal_ids is blank' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)
        group.traversal_ids = []

        assert_equal [subgroup.id], group.descendants.pluck(:id)
        assert_equal group.route_based_descendants.pluck(:id).sort, group.descendants.pluck(:id).sort
      end

      test 'falls back to route-based self_and_ancestors when traversal_ids is blank' do
        subgroup = groups(:subgroup_one_group_three)
        subgroup.traversal_ids = []

        expected = subgroup.route_based_self_and_ancestors.pluck(:id).sort
        assert_equal expected, subgroup.self_and_ancestors.pluck(:id).sort
      end

      test 'falls back to route-based self_and_descendants when traversal_ids is blank' do
        group = groups(:group_three)
        group.traversal_ids = []

        assert_equal group.route_based_self_and_descendants.pluck(:id).sort, group.self_and_descendants.pluck(:id).sort
      end

      test 'route_based_* aliases remain directly callable and unaffected by Linear being included' do
        group = groups(:group_three)
        subgroup = groups(:subgroup_one_group_three)

        assert_equal [subgroup.id], group.route_based_descendants.pluck(:id)
        assert_equal [group.id], subgroup.route_based_ancestors.pluck(:id)
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

      test 'creating a namespace logs an extra logidze version (traversal_ids written in a separate ' \
           'update_column after insert, now that postgres generates the id instead of ruby)' do
        parent = groups(:group_one)

        new_group = Group.create!(name: 'Linear Traversal Logidze Group', path: 'linear-traversal-logidze-group',
                                  parent:)
        new_group.create_logidze_snapshot!

        assert_equal 2, new_group.log_data.version
      end

      test 'reparenting updates traversal_ids for the namespace and all of its descendants' do
        new_root = Group.create!(name: 'Linear Traversal New Root', path: 'linear-traversal-new-root')
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)

        subgroup.update!(parent: new_root)
        subgroup.reload
        project.reload

        assert_equal [new_root.id, subgroup.id], subgroup.traversal_ids
        assert_equal [new_root.id, subgroup.id, project.id], project.traversal_ids
      end

      test 'reparenting does not touch traversal_ids when parent_id does not change' do
        subgroup = groups(:subgroup_one_group_three)
        original_traversal_ids = subgroup.traversal_ids

        subgroup.update!(description: 'updated description')

        assert_equal original_traversal_ids, subgroup.reload.traversal_ids
      end

      test 'reparenting logs an extra logidze version for the reparented namespace itself (its own ' \
           'traversal_ids update_column after the parent_id save), but only one new version for descendants' do
        new_root = Group.create!(name: 'Linear Traversal New Root 2', path: 'linear-traversal-new-root-2')
        subgroup = groups(:subgroup_one_group_three)
        project = namespaces_project_namespaces(:project4_namespace)
        subgroup.create_logidze_snapshot!
        project.create_logidze_snapshot!

        assert_equal 1, subgroup.log_data.version
        assert_equal 1, project.log_data.version

        subgroup.update!(parent: new_root)

        # `log_data` is excluded from normal SELECTs for `Namespace` (see
        # `config.logidze.ignore_log_data_by_default` in
        # config/application.rb), so `#reload` won't pick up its new value -
        # `#reload_log_data` fetches it explicitly instead.
        subgroup.reload_log_data
        project.reload_log_data

        # subgroup is written to twice (the primary `parent_id` save, plus
        # the separate `update_column` that sets its own `traversal_ids`
        # afterwards), so it logs two new versions; project (a descendant,
        # updated only via the single `sync_descendants_traversal_ids`
        # UPDATE) logs exactly one.
        assert_equal 3, subgroup.log_data.version
        assert_equal 2, project.log_data.version
      end
    end
  end
end
