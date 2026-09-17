# frozen_string_literal: true

require 'test_helper'

module Projects
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @parent_namespace = namespaces_user_namespaces(:john_doe_namespace)
      @parent_group_namespace = groups(:group_one)
      Flipper.enable(:global_groups)
    end

    def teardown
      Flipper.disable(:global_groups)
    end

    test 'create project with valid params under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }

      # The user is already a member of a parent group so they are not added as a direct member to this project
      assert_difference -> { Project.count } => 1, -> { Member.count } => 1, -> { NamespaceBot.count } => 0 do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'proj1', path: 'proj1' } }

      assert_no_difference ['Project.count', 'Member.count'] do
        Projects::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'skips post-persistence actions when project is not persisted' do
      invalid_params = { namespace_attributes: { name: 'proj1', path: 'proj1' } }
      service = Projects::CreateService.new(@user, invalid_params)
      service.expects(:create_automation_bot).never
      service.expects(:create_activities).never

      project = service.execute

      assert_not project.persisted?
    end

    test 'runs post-persistence actions when project is persisted' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }
      service = Projects::CreateService.new(@user, valid_params)
      service.expects(:create_automation_bot).once
      service.expects(:create_activities).once

      project = service.execute

      assert_predicate project, :persisted?
    end

    test 'create project with valid params but incorrect permissions under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { Projects::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::CreateService.new(user, valid_params).execute
      end

      assert_equal Namespaces::UserNamespacePolicy, exception.policy
      assert_equal :create?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/user_namespace.create?', name: @parent_namespace.name),
                   exception.result.message
    end

    test 'create project with valid params under group namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_group_namespace.id } }

      # The user is already a member of a parent group so they are not added as a direct member to this project
      assert_difference -> { Project.count } => 1, -> { Member.count } => 1, -> { NamespaceBot.count } => 0 do
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
      assert_difference -> { Project.count } => 1, -> { Member.count } => 1, -> { NamespaceBot.count } => 0 do
        Projects::CreateService.new(user, valid_params).execute
      end
    end

    test 'create project within a parent group that the user is a part of with MAINTAINER role' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1',
                                               parent_id: groups(:subgroup_one_group_three).id } }
      user = users(:micha_doe)

      assert_difference -> { Project.count } => 1, -> { Member.count } => 2, -> { NamespaceBot.count } => 0 do
        Projects::CreateService.new(user, valid_params).execute
      end
    end

    test 'create project within a parent group that the user is a part of with role < MAINTAINER' do
      parent_namespace = groups(:subgroup_one_group_three)
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1',
                                               parent_id: parent_namespace.id } }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::CreateService.new(user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :create?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.create?', name: parent_namespace.name),
                   exception.result.message
    end

    test 'valid authorization to create project' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }

      assert_authorized_to(:create?, @parent_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @user }) do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project logged using logidze' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }
      project = Projects::CreateService.new(@user, valid_params).execute
      project_namespace = project.namespace

      project_namespace.create_logidze_snapshot!

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size
      assert_equal 'proj1', project_namespace.at(version: 1).name
      assert_equal 'proj1', project_namespace.at(version: 1).path
    end

    test 'create project with public parent namespace' do
      public_group_namespace = groups(:public_group1)
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: public_group_namespace.id } }

      project = Projects::CreateService.new(@user, valid_params).execute

      assert project.namespace.public?
    end

    test 'adds project creation errors to the project namespace' do
      error_message = 'Project could not be created'
      service = Projects::CreateService.new(@user, namespace_attributes: { parent_id: @parent_namespace.id })
      service.project.build_namespace(name: 'proj1', path: 'proj1', parent: @parent_namespace, owner: @user)
      service.stubs(:create_associations).raises(Projects::CreateService::ProjectCreateError, error_message)

      project = service.execute

      assert_same service.project, project
      assert_equal [error_message], project.namespace.errors[:base]
    end

    test 'does not make project public when global groups are disabled' do
      Flipper.disable(:global_groups)
      public_group_namespace = groups(:public_group1)
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: public_group_namespace.id } }

      project = Projects::CreateService.new(@user, valid_params).execute

      assert_not project.namespace.public?
    end
  end
end
