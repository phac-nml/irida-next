# frozen_string_literal: true

require 'test_helper'

class UserNamespaceTest < ActiveSupport::TestCase
  def setup
    @user_namespace = namespaces_user_namespaces(:john_doe_namespace)
  end

  test 'valid user namespace' do
    assert @user_namespace.valid?
  end

  test '#ancestor_ids' do
    assert_equal [], @user_namespace.ancestor_ids
  end

  test '#ancestors' do
    assert_equal [], @user_namespace.ancestors
  end

  test '#self_and_ancestors' do
    assert_equal [@user_namespace], @user_namespace.self_and_ancestors
  end

  test '#descendant_ids' do
    assert_equal [
      namespaces_project_namespaces(:john_doe_project2_namespace).id,
      namespaces_project_namespaces(:john_doe_project3_namespace).id
    ],
                 @user_namespace.descendant_ids
  end

  test '#descendants' do
    assert_equal [
      namespaces_project_namespaces(:john_doe_project2_namespace),
      namespaces_project_namespaces(:john_doe_project3_namespace)
    ],
                 @user_namespace.descendants
  end

  test '#self_and_descendants' do
    assert_equal [
      @user_namespace,
      namespaces_project_namespaces(:john_doe_project2_namespace),
      namespaces_project_namespaces(:john_doe_project3_namespace)
    ],
                 @user_namespace.self_and_descendants
  end

  test '#human_name' do
    assert_equal @user_namespace.route.name, @user_namespace.human_name
  end

  test '#group_namespace?' do
    assert_not @user_namespace.group_namespace?
  end

  test '#project_namespace?' do
    assert_not @user_namespace.project_namespace?
  end

  test '#user_namespace?' do
    assert @user_namespace.user_namespace?
  end

  test '#owner_required?' do
    assert @user_namespace.owner_required?
  end

  test '#validate_type' do
    assert_nil @user_namespace.validate_type
  end

  test '#validate_parent_type' do
    assert_nil @user_namespace.validate_parent_type
  end

  test '#full_name' do
    assert_equal @user_namespace.route.name, @user_namespace.full_name
  end

  test '#full_path' do
    assert_equal @user_namespace.route.path, @user_namespace.full_path
  end
end
