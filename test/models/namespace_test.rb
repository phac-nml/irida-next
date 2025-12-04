# frozen_string_literal: true

require 'test_helper'

class NamespaceTest < ActiveSupport::TestCase
  test 'cannot create with nil type' do
    namespace = Namespace.new(name: 'base', path: 'base')
    assert_raises NotImplementedError do
      assert_not namespace.valid?, 'namespace is valid without a type'
      assert_not_nil namespace.errors[:type], 'no validation error for type present'
    end
  end

  test '#self_and_ancestors when collection is empty' do
    assert_equal [], Namespace.none.self_and_ancestors
  end

  test '#self_and_ancestors when collection is non empty' do
    assert (Group.where(id: groups(:group_one).id).self_and_ancestors - Group.where(id: [
      groups(:group_one)
    ].map(&:id))).empty?
  end

  test '#self_and_decendants when collection is empty' do
    assert_equal [], Namespace.none.self_and_descendants
  end

  test '#self_and_descendants when collection is non empty' do
    assert (Group.where(id: groups(:group_three).id).self_and_descendants - Group.where(id: [
      groups(:group_three), groups(:subgroup_one_group_three)
    ].map(&:id))).empty?
  end

  test '#without_descendants when collection is empty' do
    assert_equal [], Namespace.none.without_descendants
  end

  test '#without_descendants when collection has one item' do
    assert (Group.where(id: groups(:group_three).id).without_descendants - Group.where(id: [
      groups(:group_three)
    ].map(&:id))).empty?
  end

  test '#without_descendants when collection has no related items' do
    assert (Group.where(id: [groups(:group_two).id,
                             groups(:group_three).id]).without_descendants - Group.where(id: [
                               groups(:group_two), groups(:group_three)
                             ].map(&:id))).empty?
  end

  test '#without_descendants when collection has related items' do
    assert (Group.where(id: [groups(:group_one).id,
                             groups(:group_three).id]).self_and_descendants.without_descendants - Group.where(id: [
                               groups(:group_one), groups(:group_three)
                             ].map(&:id))).empty?
  end

  test 'subtract_from_metadata_summary_count with valid metadata' do
    project29 = namespaces_project_namespaces(:project29_namespace)
    sample32 = samples(:sample32)
    old_namespaces = project29.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])

    assert_equal 1, project29['metadata_summary']['metadatafield1']
    assert_equal 1, project29['metadata_summary']['metadatafield2']

    Namespace.subtract_from_metadata_summary_count(old_namespaces, sample32.metadata, true)

    assert_nil project29.reload['metadata_summary']['metadatafield1']
    assert_nil project29.reload['metadata_summary']['metadatafield2']
  end

  test 'add_to_metadata_summary_count with valid metadata' do
    project1 = namespaces_project_namespaces(:project1_namespace)
    sample32 = samples(:sample32)

    new_namespaces = project1.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])

    assert_equal 10, project1['metadata_summary']['metadatafield1']
    assert_equal 35, project1['metadata_summary']['metadatafield2']
    assert_equal 633, project1.parent['metadata_summary']['metadatafield1']
    assert_equal 106, project1.parent['metadata_summary']['metadatafield2']

    Namespace.add_to_metadata_summary_count(new_namespaces, sample32.metadata, true)

    assert_equal 11, project1.reload['metadata_summary']['metadatafield1']
    assert_equal 36, project1.reload['metadata_summary']['metadatafield2']
    assert_equal 634, project1.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 107, project1.parent.reload['metadata_summary']['metadatafield2']
  end

  test 'add_to_metadata_summary_count with empty metadata' do
    project1 = namespaces_project_namespaces(:project1_namespace)
    sample32 = samples(:sample32)
    sample32.metadata = {}
    sample32.metadata_provenance = {}
    sample32.save

    new_namespaces = project1.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])

    assert_no_changes -> { project1.reload.metadata_summary } do
      assert_no_changes -> { project1.parent.reload.metadata_summary } do
        Namespace.add_to_metadata_summary_count(new_namespaces, sample32.metadata, true)
      end
    end
  end

  test 'subtract_from_metadata_summary_count with empty metadata' do
    project29 = namespaces_project_namespaces(:project29_namespace)
    sample32 = samples(:sample32)
    sample32.metadata = {}
    sample32.metadata_provenance = {}
    sample32.save

    old_namespaces = project29.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])

    assert_no_changes -> { project29.reload.metadata_summary } do
      assert_no_changes -> { project29.parent.reload.metadata_summary } do
        Namespace.subtract_from_metadata_summary_count(old_namespaces, sample32.metadata, true)
      end
    end
  end
end
