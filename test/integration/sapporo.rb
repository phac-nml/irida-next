# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class IntegrationSapporoTest < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_end_to_end)
    Rails.configuration.ga4gh_wes_server_endpoint = 'http://localhost:1122/'
  end

  def teardown
    Rails.configuration.ga4gh_wes_server_endpoint = nil
  end

  test 'integration sapporo end to end' do
    # Temp
    skip

    # Before starting test, check if Sapporo Integration is running.
    begin
      ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new
      ga4gh_client.service_info
    rescue Integrations::ApiExceptions::ConnectionError
      skip 'Sapporo server is not running'
    end

    assert_equal 'initial', @workflow_execution.state
    assert_not @workflow_execution.cleaned?

    WorkflowExecutionPreparationJob.perform_later(@workflow_execution)

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionSubmissionJob)
    assert_equal 'prepared', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionStatusJob)
    assert_equal 'submitted', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(delay_seconds: 10, except: WorkflowExecutionCompletionJob)
    assert_equal 'completing', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionCleanupJob)
    assert_equal 'completed', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially

    assert_equal 'completed', @workflow_execution.reload.state
    assert @workflow_execution.cleaned?
  end
end
