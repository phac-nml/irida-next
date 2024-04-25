# frozen_string_literal: true

require 'active_storage_test_case'
require 'test_helper'
require 'webmock/minitest'

module WorkflowExecutions
  class CreateServiceTest < ActiveStorageTestCase
    def setup
      @user = users(:john_doe)
    end

    test 'test create new workflow execution' do
      workflow_params1 = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id
      }

      workflow_params2 = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew2',
        submitter_id: @user.id
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs')
        .to_return(body: '{ "run_id": "create_run_1" }',
                   headers: { content_type:
                            'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_1/status')
        .to_return(body: '{ "run_id": "create_run_1", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      # do not perform completion job as this tests scope does not contain blob storage files
      assert_performed_jobs 3, except: WorkflowExecutionCompletionJob do
        @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params1).execute
      end

      # don't perform the preparation job as we want to check that the workflow execution is new
      assert_performed_jobs 0, except: WorkflowExecutionPreparationJob do
        @workflow_execution2 = WorkflowExecutions::CreateService.new(@user, workflow_params2).execute
      end

      assert_equal 'completing', @workflow_execution.reload.state
      assert_equal 'initial', @workflow_execution2.reload.state

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs')
        .to_return(body: '{ "run_id": "create_run_2" }',
                   headers: { content_type:
                            'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_2/status')
        .to_return(body: '{ "run_id": "create_run_2", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      perform_enqueued_jobs except: WorkflowExecutionCompletionJob do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution2)
      end

      assert_equal 'completing', @workflow_execution2.reload.state
    end

    test 'test create workflow execution completion step' do
      # prep test
      @workflow_execution_completing = workflow_executions(:irida_next_example_completing_a)
      blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_completing.blob_run_directory = blob_run_directory_a
      @workflow_execution_completing.save!

      # create file blobs
      make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/iridanext.output.json',
        blob_run_directory: blob_run_directory_a,
        gzip: true
      )
      make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/summary.txt',
        blob_run_directory: blob_run_directory_a
      )

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/my_run_id_a/status')
        .to_return(body: '{ "run_id": "create_run_1", "state": "COMPLETE" }',
                   headers: { content_type:
                           'application/json' })

      # start test
      assert_equal 'completing', @workflow_execution_completing.state

      assert_performed_jobs 2, only: [WorkflowExecutionStatusJob, WorkflowExecutionCompletionJob] do
        WorkflowExecutionStatusJob.perform_later(@workflow_execution_completing)
      end

      assert_equal 'completed', @workflow_execution_completing.reload.state
    end

    test 'test create new workflow execution with missing required workflow name' do
      workflow_params = {
        metadata:
          { workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages.include?('Metadata root is missing required keys: workflow_name')
      assert_enqueued_jobs 0
    end

    test 'test create new workflow execution with missing required workflow version' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages
                                .include?('Metadata root is missing required keys: workflow_version')
      assert_enqueued_jobs 0
    end

    test 'test workflow execution canceled' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "create_run_4" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_4/status')
        .to_return(body: '{ "run_id": "run123", "state": "CANCELING" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'initial', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'canceled', @workflow_execution.reload.state
    end

    test 'test workflow execution error' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { '-r': 'dev' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "create_run_5" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_5/status')
        .to_return(body: '{ "run_id": "create_run_5", "state": "EXECUTOR_ERROR" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'initial', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'error', @workflow_execution.reload.state
    end

    test 'test create new workflow execution sanitizes params' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample',
            workflow_version: '1.0.2' },
        workflow_params:
        {
          assembler: '',
          project_name: 'assembly',
          random_seed: '0'
        },
        workflow_type: 'NFL',
        workflow_type_version: 'DSL2',
        workflow_engine: 'nextflow',
        workflow_engine_version: '23.10.0',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexample',
        submitter_id: @user.id
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert_equal '', @workflow_execution.workflow_params['assembler']
      assert_equal 'assembly', @workflow_execution.workflow_params['project_name']
      assert_equal 0, @workflow_execution.workflow_params['random_seed']
      expected_tags = { 'createdBy' => @user.email }
      assert_equal expected_tags, @workflow_execution.tags
      assert_enqueued_jobs 1
    end
  end
end
