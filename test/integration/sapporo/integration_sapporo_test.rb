# frozen_string_literal: true

require 'test_helper'

class IntegrationSapporoTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    @workflow_execution = workflow_executions(:irida_next_example_end_to_end)
    Rails.configuration.ga4gh_wes_server_endpoint = ENV.fetch('GA4GH_WES_URL', 'http://localhost:1122/')
  end

  def teardown
    Rails.configuration.ga4gh_wes_server_endpoint = nil
  end

  test 'integration sapporo end to end' do
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

    perform_enqueued_jobs(only: WorkflowExecutionPreparationJob)
    assert_equal 'prepared', @workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionSubmissionJob)
    assert_equal 'submitted', @workflow_execution.reload.state

    # keep performing status jobs until we reach completing state
    perform_enqueued_jobs(only: WorkflowExecutionStatusJob) while enqueued_jobs.any? do |job|
      job['job_class'] == WorkflowExecutionStatusJob.name
    end
    assert_equal 'completing', @workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob)
    assert_equal 'completed', @workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob)

    assert_equal 'completed', @workflow_execution.reload.state
    assert @workflow_execution.cleaned?
  end

  test 'integration sapporo cleaned files' do
    # Before starting test, check if Sapporo Integration is running.
    begin
      ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new
      ga4gh_client.service_info
    rescue Integrations::ApiExceptions::ConnectionError
      skip 'Sapporo server is not running'
    end

    # Run workflow execution until completion stage is done.
    assert_equal 'initial', @workflow_execution.state
    assert_not @workflow_execution.cleaned?
    WorkflowExecutionPreparationJob.perform_later(@workflow_execution)

    allowed_jobs = [WorkflowExecutionPreparationJob, WorkflowExecutionSubmissionJob,
                    WorkflowExecutionStatusJob, WorkflowExecutionCompletionJob]
    allowed_jobs_names = allowed_jobs.map(&:name)
    perform_enqueued_jobs(only: allowed_jobs) while enqueued_jobs.any? do |job|
      allowed_jobs_names.include?(job['job_class'])
    end

    assert_equal 'completed', @workflow_execution.reload.state

    # check that inputs have been saved to appropriate blobs
    samplesheet_file = JSON.parse(@workflow_execution.as_wes_params[:workflow_params])['input']
    assert File.exist?(samplesheet_file)
    csv_file = CSV.read(samplesheet_file)
    input_file1 = csv_file[1][1]
    input_file2 = csv_file[1][2]
    assert File.exist?(input_file1)
    assert File.exist?(input_file2)

    # check that outputs have been saved to appropriate blobs
    outdir = JSON.parse(@workflow_execution.as_wes_params[:workflow_params])['outdir']
    output_file = "#{outdir}iridanext.output.json.gz"
    assert File.exist?(output_file)

    # check that original files exist
    assert @workflow_execution.samples_workflow_executions[0].sample.attachments[0].file.blob.present?
    assert @workflow_execution.samples_workflow_executions[0].sample.attachments[1].file.blob.present?

    # Run cleanup step
    perform_enqueued_jobs
    assert_equal 'completed', @workflow_execution.reload.state
    assert @workflow_execution.cleaned?

    # check that outputs we want to keep present
    assert @workflow_execution.outputs[0].file.blob.present?
    assert @workflow_execution.samples_workflow_executions[0].outputs[0].file.blob.present?

    # intermediary blobs destroyed
    assert_not File.exist?(samplesheet_file)
    assert_not File.exist?(input_file1)
    assert_not File.exist?(input_file2)
    assert_not File.exist?(output_file)

    # check that original files exist
    assert @workflow_execution.samples_workflow_executions[0].sample.attachments[0].file.blob.present?
    assert @workflow_execution.samples_workflow_executions[0].sample.attachments[1].file.blob.present?
  end
end
