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

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::TransferService.new(@project, @jane_doe).execute(new_namespace)
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :transfer?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.transfer?',
                          name: @project.name),
                   exception.result.message
    end

    test 'transfer project without target namespace permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      assert_raises(ActionPolicy::Unauthorized) do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end
    end

    test 'transfer project to namespace containing project with same name' do
      project = projects(:john_doe_project2)
      group_one = groups(:group_one)

      assert_not Projects::TransferService.new(project, @john_doe).execute(group_one)
    end

    test 'authorize allowed to transfer project with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer?, @project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Projects::TransferService.new(@project,
                                      @john_doe).execute(new_namespace)
      end
    end

    test 'authorize allowed to transfer to namespace' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer_into_namespace?, new_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @john_doe }) do
        Projects::TransferService.new(@project,
                                      @john_doe).execute(new_namespace)
      end
    end

    test 'project transfer changes logged using logidze' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      assert_changes -> { project_namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal groups(:group_one), project_namespace.at(version: 1).parent

      assert_equal new_namespace, project_namespace.at(version: 2).parent
    end

    test 'project transfer changes logged using logidze switch version' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      assert_changes -> { project_namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal groups(:group_one), project_namespace.at(version: 1).parent

      assert_equal new_namespace, project_namespace.at(version: 2).parent

      project_namespace.switch_to!(1)

      assert_equal groups(:group_one), project_namespace.parent
    end
  end
end
