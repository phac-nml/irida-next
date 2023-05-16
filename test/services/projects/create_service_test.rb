# frozen_string_literal: true

require 'test_helper'

module Projects
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @parent_namespace = namespaces_user_namespaces(:john_doe_namespace)
      @parent_group_namespace = groups(:group_one)
    end

    test 'create project with valid params under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }

      # The user is already a member of a parent group so they are not added as a direct member to this project
      assert_difference -> { Project.count } => 1, -> { Member.count } => 0 do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'proj1', path: 'proj1' } }

      assert_no_difference ['Project.count', 'Member.count'] do
        Projects::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create project with valid params but incorrect permissions under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { Projects::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::CreateService.new(user, valid_params).execute
      end

      assert_equal Namespaces::UserNamespacePolicy, exception.policy
      assert_equal :allowed_to_modify_projects_under_namespace?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'create project with valid params under group namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_group_namespace.id } }

      # The user is already a member of a parent group so they are not added as a direct member to this project
      assert_difference -> { Project.count } => 1, -> { Member.count } => 0 do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project with valid params but incorrect permissions under group namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_group_namespace.id } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { Projects::CreateService.new(user, valid_params).execute }
    end

    test 'create project within a parent group that the user is a part of with OWNER role' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1',
                                               parent_id: groups(:subgroup_one_group_three).id } }
      user = users(:michelle_doe)

      # The user is already a member of a parent group so they are not added as a direct member to this project
      assert_difference -> { Project.count } => 1, -> { Member.count } => 0 do
        Projects::CreateService.new(user, valid_params).execute
      end
    end

    test 'create project within a parent group that the user is a part of with MAINTAINER role' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1',
                                               parent_id: groups(:subgroup_one_group_three).id } }
      user = users(:micha_doe)

      assert_difference -> { Project.count } => 1, -> { Member.count } => 1 do
        Projects::CreateService.new(user, valid_params).execute
      end
    end

    test 'create project within a parent group that the user is a part of with role < MAINTAINER' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1',
                                               parent_id: groups(:subgroup_one_group_three).id } }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::CreateService.new(user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :allowed_to_modify_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to create project' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }

      assert_authorized_to(:allowed_to_modify_projects_under_namespace?, @parent_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @user }) do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end
  end
end
