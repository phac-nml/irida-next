# frozen_string_literal: true

require 'test_helper'

class ProjectNamespaceTest < ActiveSupport::TestCase
  def setup
    @project_namespace = namespaces_project_namespaces(:project1_namespace)
    @group_one = groups(:group_one)
  end

  test 'valid user namespace' do
    assert @project_namespace.valid?
  end

  test '#ancestors' do
    assert_equal [], @project_namespace.ancestors
  end

  test '#ancestor_ids' do
    assert_equal [], @project_namespace.ancestor_ids
  end

  test '#self_and_ancestors' do
    assert_equal [@project_namespace], @project_namespace.self_and_ancestors
  end

  test '#descendants' do
    assert_equal [],  @project_namespace.descendants
  end

  test '#self_and_descendants' do
    assert_equal [@project_namespace], @project_namespace.self_and_descendants
  end

  test '#human_name' do
    assert_equal @project_namespace.route.name, @project_namespace.human_name
  end

  test '#group_namespace?' do
    assert_not @project_namespace.group_namespace?
  end

  test '#project_namespace?' do
    assert @project_namespace.project_namespace?
  end

  test '#user_namespace?' do
    assert_not @project_namespace.user_namespace?
  end

  test '#owner_required?' do
    assert @project_namespace.owner_required?
  end

  test '#validate_type' do
    assert_nil @project_namespace.validate_type
  end

  test '#validate_parent_type' do
    assert_nil @project_namespace.validate_parent_type
  end

  test '#full_name' do
    assert_equal @project_namespace.route.name, @project_namespace.full_name
  end

  test '#full_path' do
    assert_equal @project_namespace.route.path, @project_namespace.full_path
  end

  test '#destroy removes dependant project, and members' do
    members_count = @project_namespace.project_members.count
    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => -1,
      -> { Project.count } => -1,
      -> { Member.count } => (members_count * -1)
    ) do
      @project_namespace.destroy
    end
  end

  test '#destroy removes dependant project, and members, then they are restored' do
    members_count = @project_namespace.project_members.count
    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => -1,
      -> { Project.count } => -1,
      -> { Member.count } => (members_count * -1)
    ) do
      @project_namespace.destroy
    end

    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => +1,
      -> { Project.count } => +1,
      -> { Member.count } => (members_count * +1)
    ) do
      Namespaces::ProjectNamespace.restore(@project_namespace.id, recursive: true)
    end
  end
end
