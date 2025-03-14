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

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel running workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_running)

      assert 'running', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel prepared workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_prepared)

      assert 'prepared', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

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

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)

      assert_equal 'canceled', @workflow_execution.reload.state
      assert @workflow_execution.cleaned?

      @workflow_execution.create_logidze_snapshot!
      assert 'canceled', @workflow_execution.state
      assert_equal 2, @workflow_execution.log_data.version
      assert_equal 2, @workflow_execution.log_data.size
    end
  end
end
