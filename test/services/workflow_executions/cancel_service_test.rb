# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancelServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
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

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution: @workflow_execution }).execute

      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceled', @workflow_execution.reload.state
      assert @workflow_execution.cleaned?

      @workflow_execution.create_logidze_snapshot!
      assert 'canceled', @workflow_execution.state
      assert_equal 2, @workflow_execution.log_data.version
      assert_equal 2, @workflow_execution.log_data.size
    end

    test 'cancel multiple workflows at once' do
      workflow_execution1 = workflow_executions(:irida_next_example_submitted)
      workflow_execution2 = workflow_executions(:irida_next_example_running)

      assert 'submitted', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(
        @user, { workflow_execution_ids: [workflow_execution1.id, workflow_execution2.id] }
      ).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?

      assert_equal 'canceling', workflow_execution1.reload.state
      assert_not workflow_execution1.cleaned?
    end
  end
end
