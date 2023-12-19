# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

module WorkflowExecutions
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'test create new workflow execution' do
      workflow_params1 = {
        metadata:
        { workflow_name: 'irida-next-example-new', workflow_version: '1.0dev' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id,
        state: 'new'
      }

      workflow_params2 = {
        metadata:
        { workflow_name: 'irida-next-example-new2', workflow_version: '1.0dev' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew2',
        submitter_id: @user.id,
        state: 'new'
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "run123" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/run123/status')
        .to_return(body: '{ "run_id": "run123", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params1
      ).execute
      @workflow_execution2 = WorkflowExecutions::CreateService.new(@user, workflow_params2).execute

      assert_equal 'new', @workflow_execution.state
      assert_equal 'new', @workflow_execution2.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'completed', @workflow_execution.reload.state
      assert_equal 'new', @workflow_execution2.reload.state

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "run234" }',
                                                                                headers: { content_type:
                 'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/run234/status')
        .to_return(body: '{ "run_id": "run234", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution2)
      end

      assert_equal 'completed', @workflow_execution2.reload.state
    end

    test 'test create new workflow execution with missing required workflow name' do
      workflow_params = {
        metadata:
        { workflow_version: '1.0dev' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id,
        state: 'new'
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages.include?('Metadata root is missing required keys: workflow_name')
      assert_enqueued_jobs 0
    end

    test 'test create new workflow execution with missing required workflow version' do
      workflow_params = {
        metadata:
        { workflow_name: 'irida-next-example-new' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id,
        state: 'new'
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages
                                .include?('Metadata root is missing required keys: workflow_version')
      assert_enqueued_jobs 0
    end

    test 'test workflow execution canceled' do
      workflow_params = {
        metadata:
        { workflow_name: 'irida-next-example-new', workflow_version: '1.0dev' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id,
        state: 'new'
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "run123" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/run123/status')
        .to_return(body: '{ "run_id": "run123", "state": "CANCELING" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'new', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'canceled', @workflow_execution.reload.state
    end

    test 'test workflow execution error' do
      workflow_params = {
        metadata:
        { workflow_name: 'irida-next-example-new', workflow_version: '1.0dev' },
        workflow_params:
        {
          '-r': 'dev',
          '--input': '/blah/samplesheet.csv',
          '--outdir': '/blah/output'
        },
        workflow_type: 'DSL2',
        workflow_type_version: '22.10.7',
        tags: [],
        workflow_engine: 'nextflow',
        workflow_engine_version: '',
        workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
        workflow_url: 'https://github.com/phac-nml/iridanextexamplenew',
        submitter_id: @user.id,
        state: 'new'
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "run123" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/run123/status')
        .to_return(body: '{ "run_id": "run123", "state": "EXECUTOR_ERROR" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'new', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'error', @workflow_execution.reload.state
    end
  end
end
