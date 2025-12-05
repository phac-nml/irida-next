# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'
require 'webmock/minitest'

class WorkflowExecutionJobTest < ActiveJobTestCase
  def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @workflow_execution_submitted = workflow_executions(:irida_next_example_submitted)
    @workflow_execution_prepared = workflow_executions(:irida_next_example_prepared)
    @workflow_execution_new = workflow_executions(:irida_next_example_new)
    @workflow_execution_completed = workflow_executions(:irida_next_example_completed)
    @workflow_execution_missing_run_id = workflow_executions(:workflow_execution_missing_run_id)
    @workflow_execution_valid = workflow_executions(:workflow_execution_valid)
    @workflow_execution_gas_clustering = workflow_executions(:workflow_execution_gasclustering)

    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json')

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"f1Fg"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/gasclustering/0.4.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"g1gh"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/gasclustering/0.4.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"h1hi"]' })
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'nil workflow execution' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(nil)
  end

  test 'missing namespace' do
    @workflow_execution_new.namespace = nil
    assert_not WorkflowExecutionJob.new.validate_initial_state(@workflow_execution_new)
  end

  test 'state in expected states' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, %i[prepared submitted]
    )
  end

  test 'state not in expected states' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_completed, %i[prepared submitted]
    )
  end

  test 'run id validation success' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, validate_run_id: true
    )
  end

  test 'run id validation failure' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_missing_run_id, validate_run_id: true
    )
  end

  test 'all arguments' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, %i[prepared submitted], validate_run_id: true
    )
  end

  test 'maximum_run_time at entry level (Irida Next Example Pipeline)' do
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines/pipelines.json',
                         pipeline_schema_file_dir: @pipeline_schema_file_dir)

    assert_equal 150, WorkflowExecutionJob.new.maximum_run_time(@workflow_execution_submitted)
  end

  test 'maximum_run_time at version level (1.0.3)' do
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines/pipelines.json',
                         pipeline_schema_file_dir: @pipeline_schema_file_dir)

    assert_equal 65,
                 WorkflowExecutionJob.new.maximum_run_time(@workflow_execution_valid)
  end

  test 'status_check_interval default' do
    assert_equal 30, WorkflowExecutionJob.new.status_check_interval(@workflow_execution_submitted)
  end

  test 'status_check_interval at version level (1.0.3)' do
    assert_equal 45, WorkflowExecutionJob.new.status_check_interval(@workflow_execution_valid)
  end

  test 'maximum_run_time not set' do
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines/pipelines.json',
                         pipeline_schema_file_dir: @pipeline_schema_file_dir)

    assert_nil WorkflowExecutionJob.new.maximum_run_time(@workflow_execution_gas_clustering)
  end
end
