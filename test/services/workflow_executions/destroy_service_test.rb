# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @user_destroyable = users(:janitor_doe)

      @namespace = projects(:project1).namespace
    end

    test 'should not destroy a workflow execution if the user is not the submitter' do
      user = users(:jane_doe)
      workflow_execution = workflow_executions(:irida_next_example_completed)
      assert workflow_execution.completed?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          WorkflowExecutions::DestroyService.new(user, { workflow_execution: }).execute
        end

        assert_equal WorkflowExecutionPolicy, exception.policy
        assert_equal :destroy?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.workflow_execution.destroy?',
                            namespace_type: workflow_execution.namespace.type,
                            name: workflow_execution.namespace.name),
                     exception.result.message
      end
    end

    test 'should not destroy a prepared workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_prepared)
      assert workflow_execution.prepared?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should not destroy a submitted workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_submitted)
      assert workflow_execution.submitted?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should destroy a completed workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed_DELETE)
      assert workflow_execution.completed?
      assert workflow_execution.cleaned?

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(@user_destroyable, { workflow_execution: }).execute
      end
    end

    test 'should not destroy an uncleaned completed workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed_unclean)
      assert workflow_execution.completed?
      assert_not workflow_execution.cleaned?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should destroy an errored workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_error_DELETE)
      assert workflow_execution.error?
      assert workflow_execution.cleaned?

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(@user_destroyable, { workflow_execution: }).execute
      end
    end

    test 'should not destroy an uncleaned error workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_error_unclean)
      assert workflow_execution.error?
      assert_not workflow_execution.cleaned?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should not destroy a canceling workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceling)
      assert workflow_execution.canceling?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should destroy a canceled workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceled_DELETE)
      assert workflow_execution.canceled?
      assert workflow_execution.cleaned?

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(@user_destroyable, { workflow_execution: }).execute
      end
    end

    test 'should not destroy an uncleaned canceled workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceled_unclean)
      assert workflow_execution.canceled?
      assert_not workflow_execution.cleaned?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should not destroy a running workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_running)
      assert workflow_execution.running?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should not destroy a new workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_new)
      assert workflow_execution.initial?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(@user, { workflow_execution: }).execute
      end
    end

    test 'should destroy multiple workflow executions' do
      error_workflow = workflow_executions(:irida_next_example_error)
      canceled_workflow = workflow_executions(:irida_next_example_canceled)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [error_workflow.id, canceled_workflow.id] }
        ).execute
      end
    end

    test 'should partially destroy multiple workflow executions' do
      canceling_workflow = workflow_executions(:irida_next_example_canceling)
      canceled_workflow = workflow_executions(:irida_next_example_canceled)
      error_workflow = workflow_executions(:irida_next_example_error)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [canceling_workflow.id, canceled_workflow.id, error_workflow.id] }
        ).execute
      end
    end

    test 'should not destroy multiple non-deletable workflow executions' do
      canceling_workflow = workflow_executions(:irida_next_example_canceling)
      unclean_workflow = workflow_executions(:irida_next_example_error_unclean)

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(
          @user_destroyable,
          { workflow_execution_ids: [canceling_workflow.id, unclean_workflow.id] }
        ).execute
      end
    end

    test 'should not destroy project workflow executions if user is unauthorized' do
      user = users(:jane_doe)
      valid_deletable_workflow = workflow_executions(:automated_example_completed)
      namespace = projects(:project1).namespace
      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          WorkflowExecutions::DestroyService.new(user,
                                                 { workflow_execution_ids: [valid_deletable_workflow.id],
                                                   namespace: }).execute
        end

        assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
        assert_equal :destroy_workflow_executions?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.destroy_workflow_executions?',
                            name: namespace.name),
                     exception.result.message
      end
    end

    test 'unauthorized response if group namespace is passed' do
      completed_workflow_execution = workflow_executions(:automated_example_completed)
      error_workflow_execution = workflow_executions(:automated_example_error)
      namespace = groups(:group_one)

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          WorkflowExecutions::DestroyService.new(
            @user,
            { workflow_execution_ids: [completed_workflow_execution.id, error_workflow_execution.id], namespace: }
          ).execute
        end
        assert_equal GroupPolicy, exception.policy
        assert_equal :destroy_workflow_executions?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.destroy_workflow_executions?',
                            name: namespace.name),
                     exception.result.message
      end
    end

    test 'should not destroy shared workflow executions if selected' do
      error_workflow = workflow_executions(:automated_example_error)
      canceled_workflow = workflow_executions(:automated_example_canceled)
      shared_workflow = workflow_executions(:workflow_execution_shared2)
      namespace = projects(:project1).namespace

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [error_workflow.id, canceled_workflow.id, shared_workflow.id], namespace: }
        ).execute
      end
    end

    test 'should create activity for single workflow deletion in single destroy' do
      # deletion of single workflow using row action
      canceled_workflow = workflow_executions(:automated_example_canceled)

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { PublicActivity::Activity.count } => 1 do
        WorkflowExecutions::DestroyService.new(@user,
                                               { workflow_execution: canceled_workflow,
                                                 namespace: @namespace }).execute
      end

      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.workflow_executions.destroy'
      ).order(created_at: :desc).first
      assert_equal 'namespaces_project_namespace.workflow_executions.destroy', activity.key
      assert_equal @user, activity.owner
      assert_equal 1, activity.parameters[:workflow_executions_deleted_count]
      assert_includes activity.extended_details.details['deleted_workflow_executions_data'],
                      { 'workflow_id' => canceled_workflow.id, 'workflow_name' => canceled_workflow.name }
      assert_equal 1, activity.extended_details.details['deleted_workflow_executions_data'].count
      assert_equal 'workflow_execution_destroy', activity.parameters[:action]
    end

    test 'should create activity for multiple workflow deletion' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2,
                        -> { PublicActivity::Activity.count } => 1 do
        WorkflowExecutions::DestroyService.new(@user,
                                               { workflow_execution_ids: [canceled_workflow.id, error_workflow.id],
                                                 namespace: @namespace }).execute
      end

      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.workflow_executions.destroy'
      ).order(created_at: :desc).first
      assert_equal 'namespaces_project_namespace.workflow_executions.destroy', activity.key
      assert_equal @user, activity.owner
      assert_equal 2, activity.parameters[:workflow_executions_deleted_count]
      assert_includes activity.extended_details.details['deleted_workflow_executions_data'],
                      { 'workflow_id' => error_workflow.id, 'workflow_name' => error_workflow.name },
                      { 'workflow_id' => canceled_workflow.id,
                        'workflow_name' => canceled_workflow.name }
      assert_equal 1, activity.extended_details.details['deleted_workflow_executions_data'].count
      assert_equal 'workflow_execution_destroy', activity.parameters[:action]
    end

    test 'should create activity with accurate deletion params when non-deletable workflow is selected' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)
      canceling_workflow = workflow_executions(:automated_example_canceling)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2,
                        -> { PublicActivity::Activity.count } => 1 do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [canceled_workflow.id, error_workflow.id, canceling_workflow.id],
            namespace: @namespace }
        ).execute
      end

      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.workflow_executions.destroy'
      ).order(created_at: :desc).first
      assert_equal 'namespaces_project_namespace.workflow_executions.destroy', activity.key
      assert_equal @user, activity.owner
      assert_equal 2, activity.parameters[:workflow_executions_deleted_count]
      assert_includes activity.extended_details.details['deleted_workflow_executions_data'],
                      { 'workflow_id' => error_workflow.id, 'workflow_name' => error_workflow.name }
      assert_includes activity.extended_details.details['deleted_workflow_executions_data'],
                      { 'workflow_id' => canceled_workflow.id, 'workflow_name' => canceled_workflow.name }
      assert_equal 2, activity.extended_details.details['deleted_workflow_executions_data'].count
      assert_equal 'workflow_execution_destroy', activity.parameters[:action]
    end

    test 'should not create activity if only non-deletable workflows were selected' do
      canceling_workflow = workflow_executions(:automated_example_canceling)
      submitted_workflow = workflow_executions(:automated_example_submitted)

      assert_no_difference -> { PublicActivity::Activity.count } do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [submitted_workflow.id, canceling_workflow.id],
            namespace: @namespace }
        ).execute
      end
    end

    test 'should not create activity if namespace is not declared' do
      canceling_workflow = workflow_executions(:automated_example_canceling)
      submitted_workflow = workflow_executions(:automated_example_submitted)

      assert_no_difference -> { PublicActivity::Activity.count } do
        WorkflowExecutions::DestroyService.new(
          @user,
          { workflow_execution_ids: [submitted_workflow.id, canceling_workflow.id] }
        ).execute
      end
    end
  end
end
