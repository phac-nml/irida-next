# frozen_string_literal: true

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = projects(:project1)
  end

  test 'valid project' do
    assert @project.valid?
  end

  test '#to_param' do
    assert_equal @project.path, @project.to_param
  end

  test '#description' do
    assert_equal @project.namespace.description, @project.description
  end

  test '#name' do
    assert_equal @project.namespace.name, @project.name
  end

  test '#path' do
    assert_equal @project.namespace.path, @project.path
  end

  test '#human_name' do
    assert_equal @project.namespace.human_name, @project.human_name
  end

  test '#full_path' do
    assert_equal @project.namespace.full_path, @project.full_path
  end

  test '#destroy removes dependant project namespace' do
    assert_difference(-> { Namespaces::ProjectNamespace.count } => -1) do
      @project.destroy
    end
  end

  test 'restore_namespace' do
    project_namespace = namespaces_project_namespaces(:project1_namespace)

    @project.destroy
    assert @project.deleted?

    @project.send(:restore_namespace)
    assert_not @project.reload.deleted?
  end

  test 'destroy_namespace' do
    project_namespace = namespaces_project_namespaces(:project1_namespace)

    assert_not project_namespace.deleted?
    @project.send(:destroy_namespace)

    assert project_namespace.reload.deleted?
  end
end
