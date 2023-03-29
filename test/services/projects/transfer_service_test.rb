# frozen_string_literal: true

require 'test_helper'

module Projects
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @project = projects(:project1)
    end

    test 'transfer project with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_changes -> { @project.namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end
    end

    test 'transfer project without specifying new namespace' do
      assert_not Projects::TransferService.new(@project, @john_doe).execute(nil)
    end

    test 'transfer project to namespace containing project' do
      group_one = groups(:group_one)

      assert_not Projects::TransferService.new(@project, @john_doe).execute(group_one)
    end

    test 'transfer project without project permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      assert_no_changes -> { @project.namespace.parent } do
        Projects::TransferService.new(@project, @jane_doe).execute(new_namespace)
      end
    end

    test 'transfer project without target namespace permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      assert_no_changes -> { @project.namespace.parent } do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end
    end

    test 'transfer project to namespace containing project with same name' do
      project = projects(:john_doe_project2)
      group_one = groups(:group_one)

      assert_not Projects::TransferService.new(project, @john_doe).execute(group_one)
    end
  end
end
