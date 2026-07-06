# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/faraday_test_helpers'

module WorkflowExecutions
  class WorkflowExecutionCleanupJobTest < ActiveJob::TestCase
    include FaradayTestHelpers

    def setup
      @stubs = faraday_test_adapter_stubs
    end

    def teardown
      # reset connections after each test to clear cache
      Faraday.default_connection = nil
    end

    test 'successful job on completed workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

      assert_not workflow_execution.cleaned?

      assert_difference -> { workflow_execution.outputs.count }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_includes output_filenames, 'run_log.json'
      assert_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on completed workflow execution when stdout endpoint is unavailable' do
      workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

      assert_not workflow_execution.cleaned?

      assert_difference -> { workflow_execution.outputs.count }, 1 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE', stdout_not_found: true) do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_includes output_filenames, 'run_log.json'
      assert_not_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on canceled workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceled_unclean_DELETE)

      assert_not workflow_execution.cleaned?

      assert_no_difference -> { workflow_execution.outputs.count } do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'CANCELED') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_not_includes output_filenames, 'run_log.json'
      assert_not_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on error workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

      assert_not workflow_execution.cleaned?

      assert_difference -> { workflow_execution.outputs.count }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'SYSTEM_ERROR') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_includes output_filenames, 'run_log.json'
      assert_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(12, only: Turbo::Streams::BroadcastStreamJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on error workflow execution with missing namespace' do
      workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

      workflow_execution.namespace = nil
      workflow_execution.save
      assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)

      assert_nil workflow_execution.namespace
      assert_equal 'error', workflow_execution.state
      assert_not workflow_execution.cleaned?

      assert_difference -> { workflow_execution.outputs.count }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'SYSTEM_ERROR') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_includes output_filenames, 'run_log.json'
      assert_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(14, only: Turbo::Streams::BroadcastStreamJob) # 2 queued from setting the namespace to nil
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'failed job on running workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_running)

      assert_not workflow_execution.cleaned?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(workflow_execution)
      end

      assert_not workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_not_includes output_filenames, 'run_log.json'
      assert_not_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0)
    end

    test 'failed job on cleaned workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed)

      assert workflow_execution.cleaned?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(workflow_execution)
      end

      assert workflow_execution.reload.cleaned?
      output_filenames = workflow_execution.outputs.map { |attachment| attachment.filename.to_s }
      assert_not_includes output_filenames, 'run_log.json'
      assert_not_includes output_filenames, 'run_stdout.json'

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0)
    end

    private

    def with_cleanup_service_wes_stubs(workflow_execution, run_log_state:, run_stdout: 'workflow stdout', # rubocop:disable Metrics/MethodLength
                                       stdout_not_found: false)
      mock_client = connection_builder(stubs: @stubs, connection_count: 1)

      Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
        @stubs.get("/runs/#{workflow_execution.run_id}") do |_env|
          [
            200,
            { 'Content-Type': 'application/json' },
            { run_id: workflow_execution.run_id, state: run_log_state }
          ]
        end

        if stdout_not_found
          @stubs.get("/runs/#{workflow_execution.run_id}/stdout") do |_env|
            raise Faraday::ResourceNotFound.new({
                                                  status: 'not found',
                                                  headers: '',
                                                  body: '',
                                                  request: {
                                                    method: 'get',
                                                    url: "/runs/#{workflow_execution.run_id}/stdout"
                                                  }
                                                })
          end
        else
          @stubs.get("/runs/#{workflow_execution.run_id}/stdout") do |_env|
            [
              200,
              { 'Content-Type': 'text/plain' },
              run_stdout
            ]
          end
        end

        yield
      end
    end
  end
end
