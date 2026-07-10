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
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_difference -> { log_attachment_count(workflow_execution) }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      assert workflow_execution.stdout.attached?
      assert workflow_execution.stderr.attached?
      assert_equal 'stdout.txt', workflow_execution.stdout.filename.to_s
      assert_equal 'stderr.txt', workflow_execution.stderr.filename.to_s

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'cleanup log attachment creation is idempotent when rerun' do
      workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

      assert_not workflow_execution.cleaned?

      assert_difference -> { log_attachment_count(workflow_execution) }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      workflow_execution.reload
      stdout_attachment_id = workflow_execution.stdout.attachment.id
      stderr_attachment_id = workflow_execution.stderr.attachment.id

      workflow_execution.update!(cleaned: false)

      assert_no_difference -> { log_attachment_count(workflow_execution) } do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      workflow_execution.reload
      assert_equal stdout_attachment_id, workflow_execution.stdout.attachment.id
      assert_equal stderr_attachment_id, workflow_execution.stderr.attachment.id
      assert workflow_execution.cleaned?
    end

    test 'successful job on completed workflow execution when stdout endpoint is unavailable' do
      workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

      assert_not workflow_execution.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_difference -> { log_attachment_count(workflow_execution) }, 1 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'COMPLETE', stdout_not_found: true) do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert workflow_execution.stderr.attached?
      assert_equal 'stderr.txt', workflow_execution.stderr.filename.to_s

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on canceled workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceled_unclean_DELETE)

      assert_not workflow_execution.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_no_difference -> { log_attachment_count(workflow_execution) } do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'CANCELED') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'successful job on error workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

      assert_not workflow_execution.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_difference -> { log_attachment_count(workflow_execution) }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'SYSTEM_ERROR') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      assert workflow_execution.stdout.attached?
      assert workflow_execution.stderr.attached?
      assert_equal 'stdout.txt', workflow_execution.stdout.filename.to_s
      assert_equal 'stderr.txt', workflow_execution.stderr.filename.to_s

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(10, only: Turbo::Streams::BroadcastStreamJob)
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
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_difference -> { log_attachment_count(workflow_execution) }, 2 do
        with_cleanup_service_wes_stubs(workflow_execution, run_log_state: 'SYSTEM_ERROR') do
          perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
            WorkflowExecutionCleanupJob.perform_later(workflow_execution)
          end
        end
      end

      assert workflow_execution.reload.cleaned?
      assert workflow_execution.stdout.attached?
      assert workflow_execution.stderr.attached?
      assert_equal 'stdout.txt', workflow_execution.stdout.filename.to_s
      assert_equal 'stderr.txt', workflow_execution.stderr.filename.to_s

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(12, only: Turbo::Streams::BroadcastStreamJob) # 2 queued from setting the namespace to nil
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'failed job on running workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_running)

      assert_not workflow_execution.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(workflow_execution)
      end

      assert_not workflow_execution.reload.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0)
    end

    test 'failed job on cleaned workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed)

      assert workflow_execution.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(workflow_execution)
      end

      assert workflow_execution.reload.cleaned?
      assert_not workflow_execution.stdout.attached?
      assert_not workflow_execution.stderr.attached?

      assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
      assert_enqueued_jobs(0)
    end

    private

    def with_cleanup_service_wes_stubs(workflow_execution, run_log_state:, run_stdout: 'workflow stdout', # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/ParameterLists
                                       run_stderr: 'workflow stderr', stdout_not_found: false,
                                       stderr_not_found: false)
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

        if stderr_not_found
          @stubs.get("/runs/#{workflow_execution.run_id}/stderr") do |_env|
            raise Faraday::ResourceNotFound.new({
                                                  status: 'not found',
                                                  headers: '',
                                                  body: '',
                                                  request: {
                                                    method: 'get',
                                                    url: "/runs/#{workflow_execution.run_id}/stderr"
                                                  }
                                                })
          end
        else
          @stubs.get("/runs/#{workflow_execution.run_id}/stderr") do |_env|
            [
              200,
              { 'Content-Type': 'text/plain' },
              run_stderr
            ]
          end
        end

        yield
      end
    end

    def log_attachment_count(workflow_execution)
      ActiveStorage::Attachment.where(record: workflow_execution, name: %w[stdout stderr]).count
    end
  end
end
