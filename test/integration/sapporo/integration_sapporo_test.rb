# frozen_string_literal: true

require 'test_helper'

class IntegrationSapporoTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include WorkflowExecutions

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

  test 'integration sapporo snvphylnfc end to end' do
    # Before starting test, check if Sapporo Integration is running.
    begin
      ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new
      ga4gh_client.service_info
    rescue Integrations::ApiExceptions::ConnectionError
      skip 'Sapporo server is not running'
    end

    user = users(:snvphyl_user)
    project = projects(:snvphyl_project)
    sample1 = samples(:snvphyl_sample1)
    sample1_attachment_fwd = attachments(:snvphyl_sample1_attachment_fwd)
    sample1_attachment_rev = attachments(:snvphyl_sample1_attachment_rev)
    sample1_attachment_ref = attachments(:snvphyl_sample1_attachment_ref)
    sample2 = samples(:snvphyl_sample2)
    sample2_attachment_fwd = attachments(:snvphyl_sample2_attachment_fwd)
    sample2_attachment_rev = attachments(:snvphyl_sample2_attachment_rev)

    workflow_params = { reference_sample_id: '',
                        refgenome: sample1_attachment_ref.to_global_id,
                        metadata_1_header: 'metadata_1',
                        metadata_2_header: 'metadata_2',
                        metadata_3_header: 'metadata_3',
                        metadata_4_header: 'metadata_4',
                        metadata_5_header: 'metadata_5',
                        metadata_6_header: 'metadata_6',
                        metadata_7_header: 'metadata_7',
                        metadata_8_header: 'metadata_8',
                        metadata_9_header: 'metadata_9',
                        metadata_10_header: 'metadata_10',
                        metadata_11_header: 'metadata_11',
                        metadata_12_header: 'metadata_12',
                        metadata_13_header: 'metadata_13',
                        metadata_14_header: 'metadata_14',
                        metadata_15_header: 'metadata_15',
                        metadata_16_header: 'metadata_16',
                        min_coverage_depth: 15,
                        min_mapping_percent_cov: 80,
                        min_mean_mapping_quality: 30,
                        window_size: 500,
                        density_threshold: 2,
                        snv_abundance_ratio: 0.75,
                        min_repeat_length: 150,
                        min_repeat_pid: 90,
                        skip_density_filter: false }

    samples_workflow_executions_attributes = {
      '0': {
        sample_id: sample1.id,
        samplesheet_params: {
          sample: sample1.puid,
          sample_name: sample1.name,
          fastq_1: sample1_attachment_fwd.to_global_id, # rubocop:disable Naming/VariableNumber
          fastq_2: sample1_attachment_rev.to_global_id, # rubocop:disable Naming/VariableNumber
          reference_assembly: ''
        }.merge(sample1.metadata)
      },
      '1': {
        sample_id: sample2.id,
        samplesheet_params: {
          sample: sample2.puid,
          sample_name: sample2.name,
          fastq_1: sample2_attachment_fwd.to_global_id, # rubocop:disable Naming/VariableNumber
          fastq_2: sample2_attachment_rev.to_global_id, # rubocop:disable Naming/VariableNumber
          reference_assembly: ''
        }.merge(sample2.metadata)
      }
    }

    workflow_execution_params = {
      metadata: {
        pipeline_id: 'phac-nml/snvphylnfc',
        workflow_version: '2.4.0'
      },
      submitter_id: user.id,
      namespace_id: project.namespace.id,
      workflow_params: workflow_params,
      samples_workflow_executions_attributes: samples_workflow_executions_attributes,
      name: 'SNVPhyl Workflow End To End'
    }

    workflow_execution = WorkflowExecutions::CreateService.new(user, workflow_execution_params).execute

    assert_equal 'initial', workflow_execution.state
    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionPreparationJob)
    assert_equal 'prepared', workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionSubmissionJob)
    assert_equal 'submitted', workflow_execution.reload.state

    # keep performing status jobs until we reach completing state
    perform_enqueued_jobs(only: WorkflowExecutionStatusJob) while enqueued_jobs.any? do |job|
      job['job_class'] == WorkflowExecutionStatusJob.name
    end
    assert_equal 'completing', workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob)
    assert_equal 'completed', workflow_execution.reload.state

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob)

    assert_equal 'completed', workflow_execution.reload.state
    assert workflow_execution.cleaned?
  end

  test 'workflow execution metadata sends to WES' do
    # Before starting test, check if Sapporo Integration is running.
    begin
      ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new
      ga4gh_client.service_info
    rescue Integrations::ApiExceptions::ConnectionError
      skip 'Sapporo server is not running'
    end

    @user = users(:john_doe)
    @project = projects(:project1)
    @sample = samples(:sample1)
    @attachment = attachments(:attachment1)
    @samples_workflow_executions_attributes = {
      '0': {
        sample_id: @sample.id,
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment.to_global_id # rubocop:disable Naming/VariableNumber
        }
      }
    }

    workflow_params = {
      metadata:
        { pipeline_id: 'phac-nml/iridanextexample',
          workflow_version: '1.0.2' },
      submitter_id: @user.id,
      namespace_id: @project.namespace.id,
      samples_workflow_executions_attributes: @samples_workflow_executions_attributes,
      name: 'Workflow With Tags'
    }

    @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

    assert_equal 'initial', @workflow_execution.state
    assert_not @workflow_execution.cleaned?

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

    run_id = @workflow_execution.run_id
    response = ga4gh_client.get_run_log(run_id)
    assert_equal run_id, response[:run_id]
    assert_equal 'COMPLETE', response[:state]
    # Verify the metadata was sent to WES
    expected_tags = { createdBy: @user.email, namespaceId: @workflow_execution.namespace.puid,
                      samplesCount: @workflow_execution.samples_workflow_executions.size.to_s }
    assert_equal expected_tags, @workflow_execution.tags.transform_keys(&:to_sym)
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
