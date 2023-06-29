# frozen_string_literal: true

require 'test_helper'

module Projects
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'update project with valid params' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }

      assert_changes -> { [@project.name, @project.path] }, to: %w[new-project1-name new-project1-path] do
        Projects::UpdateService.new(@project, @user, valid_params).execute
      end
    end

    test 'update project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'p1', path: 'p1' } }

      assert_no_difference ['Project.count', 'Member.count'] do
        Projects::UpdateService.new(@project, @user, invalid_params).execute
      end
    end

    test 'update project with incorrect permissions' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::UpdateService.new(@project, user, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :update?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update?', name: @project.name),
                   exception.result.message
    end

    test 'valid authorization to update project' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }

      assert_authorized_to(:update?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Projects::UpdateService.new(@project, @user,
                                    valid_params).execute
      end
    end

    test 'project update changes logged using logidze' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      valid_params = { namespace_attributes: { name: 'new-project-name', path: 'new-project-path' } }

      assert_changes -> { [@project.name, @project.path] }, to: %w[new-project-name new-project-path] do
        Projects::UpdateService.new(@project, @user, valid_params).execute
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal 'Project 1', project_namespace.at(version: 1).name
      assert_equal 'project-1', project_namespace.at(version: 1).path

      assert_equal 'new-project-name', project_namespace.at(version: 2).name
      assert_equal 'new-project-path', project_namespace.at(version: 2).path

      # Description was not updated so it should not be in the changes log
      assert_nil project_namespace.diff_from(version: 1)['changes']['description']
    end

    test 'project update changes logged using logidze switch version' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      valid_params = { namespace_attributes: { name: 'new-project-name', path: 'new-project-path' } }

      assert_changes -> { [@project.name, @project.path] }, to: %w[new-project-name new-project-path] do
        Projects::UpdateService.new(@project, @user, valid_params).execute
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal 'Project 1', project_namespace.at(version: 1).name
      assert_equal 'project-1', project_namespace.at(version: 1).path

      assert_equal 'new-project-name', project_namespace.at(version: 2).name
      assert_equal 'new-project-path', project_namespace.at(version: 2).path

      project_namespace.switch_to!(1)

      assert_equal 1, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal 'Project 1', @project.name
      assert_equal 'project-1', @project.path
    end
  end
end
