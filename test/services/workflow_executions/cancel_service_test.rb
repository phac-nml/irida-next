# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancelServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @namespace = namespaces_project_namespaces(:project1_namespace)
      @project_workflow_running = workflow_executions(:automated_example_running)
      @project_workflow_submitted = workflow_executions(:automated_example_submitted)
      @project_workflow_completed = workflow_executions(:automated_example_completed)
    end

    test 'cancel submitted workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_submitted)

      assert 'submitted', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel running workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_running)

      assert 'running', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel prepared workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_prepared)

      assert 'prepared', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceled', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel initial workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_new)

      @workflow_execution.create_logidze_snapshot!

      assert 'initial', @workflow_execution.state
      assert_equal 1, @workflow_execution.log_data.version
      assert_equal 1, @workflow_execution.log_data.size

      assert WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute

      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceled', @workflow_execution.reload.state
      assert @workflow_execution.cleaned?

      @workflow_execution.create_logidze_snapshot!
      assert 'canceled', @workflow_execution.state
      assert_equal 2, @workflow_execution.log_data.version
      assert_equal 2, @workflow_execution.log_data.size
    end

    test 'cancel multiple workflows that belong to user at once' do
      workflow_execution1 = workflow_executions(:irida_next_example_submitted)
      workflow_execution2 = workflow_executions(:irida_next_example_running)

      assert 'submitted', workflow_execution1.state
      assert 'running', workflow_execution2.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id] }
      ).execute

      assert_enqueued_jobs(2, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      assert_equal 'canceling', workflow_execution2.reload.state
      assert_not workflow_execution2.cleaned?
    end

    test 'partially cancel multiple workflows that belong to user at once' do
      workflow_execution1 = workflow_executions(:irida_next_example_submitted)
      workflow_execution2 = workflow_executions(:irida_next_example_completed)

      assert 'submitted', workflow_execution1.state
      assert 'completed', workflow_execution2.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id] }
      ).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      workflow_execution2.reload.state
      assert_not_equal 'canceling', workflow_execution2.state
      assert_not_equal 'canceled', workflow_execution2.state
      assert_equal 'completed', workflow_execution2.state
      assert workflow_execution2.cleaned?
    end

    test 'cancel multiple project workflows at once' do
      workflow_execution1 = workflow_executions(:automated_example_submitted)
      workflow_execution2 = workflow_executions(:automated_example_prepared)

      assert 'submitted', workflow_execution1.state
      assert 'prepared', workflow_execution2.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id], namespace: @namespace }
      ).execute

      assert_enqueued_jobs(2, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      assert_equal 'canceled', workflow_execution2.reload.state
      assert_not workflow_execution2.cleaned?
    end

    test 'partially cancel multiple project workflows at once' do
      workflow_execution1 = workflow_executions(:automated_example_submitted)
      workflow_execution2 = workflow_executions(:automated_example_completed)

      assert 'submitted', workflow_execution1.state
      assert 'completed', workflow_execution2.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id], namespace: @namespace }
      ).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      workflow_execution2.reload.state
      assert_not_equal 'canceling', workflow_execution2.state
      assert_not_equal 'canceled', workflow_execution2.state
      assert_equal 'completed', workflow_execution2.state
      assert workflow_execution2.cleaned?
    end

    test 'cannot cancel shared workflows to project' do
      workflow_execution1 = workflow_executions(:automated_example_submitted)
      workflow_execution2 = workflow_executions(:workflow_execution_shared4)

      assert 'submitted', workflow_execution1.state
      assert 'running', workflow_execution2.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id], namespace: @namespace }
      ).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      workflow_execution2.reload.state
      assert_not_equal 'canceling', workflow_execution2.state
      assert_not_equal 'canceled', workflow_execution2.state
      assert_equal 'running', workflow_execution2.state
    end

    # cancel through action link on table
    test 'maintainer can cancel a single project workflow execution' do
      valid_params = { namespace: @namespace,
                       workflow_execution: @project_workflow_running }
      user = users(:joan_doe)

      assert_authorized_to(:cancel?, @project_workflow_running, with: WorkflowExecutionPolicy, context: { user: }) do
        WorkflowExecutions::CancelService.new(user, valid_params).execute
      end
    end

    test 'analyst cannot cancel a single project workflow execution' do
      valid_params = { namespace: @namespace,
                       workflow_execution: @project_workflow_running }
      user = users(:michelle_doe)

      assert_raises(ActionPolicy::Unauthorized) { WorkflowExecutions::CancelService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::CancelService.new(user, valid_params).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :cancel?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.cancel?',
                          namespace_type: @project_workflow_running.namespace.type,
                          name: @project_workflow_running.namespace.name),
                   exception.result.message
    end

    # cancel through dropdown action
    test 'authorized maintainer can cancel multiple project workflow executions' do
      valid_params = { namespace: @namespace,
                       workflow_execution_ids: [@project_workflow_running.id, @project_workflow_submitted.id] }
      user = users(:joan_doe)

      assert_authorized_to(:cancel_workflow_executions?, @namespace, with: Namespaces::ProjectNamespacePolicy,
                                                                     context: { user: }) do
        WorkflowExecutions::CancelService.new(user, valid_params).execute
      end
    end

    test 'unauthorized analyst cannot cancel multiple project workflow executions policy test' do
      valid_params = { namespace: @namespace,
                       workflow_execution_ids: [@project_workflow_running.id, @project_workflow_submitted.id] }
      user = users(:michelle_doe)

      assert_raises(ActionPolicy::Unauthorized) { WorkflowExecutions::CancelService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::CancelService.new(user, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :cancel_workflow_executions?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.cancel_workflow_executions?',
                          name: @namespace.name),
                   exception.result.message
    end

    test 'cannot cancel workflow that does not belong to user when namespace is nil' do
      user = users(:michelle_doe)
      workflow_execution = workflow_executions(:irida_next_example_running)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::CancelService.new(user, { workflow_execution: }).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :cancel?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.cancel?',
                          namespace_type: workflow_execution.namespace.type,
                          name: workflow_execution.namespace.name),
                   exception.result.message
    end
  end
end
