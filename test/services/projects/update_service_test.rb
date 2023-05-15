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
      assert_equal :allowed_to_modify_project_namespace?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to update project' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }

      assert_authorized_to(:allowed_to_modify_project_namespace?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Projects::UpdateService.new(@project, @user,
                                    valid_params).execute
      end
    end
  end
end
