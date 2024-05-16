# frozen_string_literal: true

require 'active_storage_test_case'
require 'test_helper'
require 'webmock/minitest'

module WorkflowExecutions
  class EndToEndest < ActiveStorageTestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
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
        submitter_id: @user.id,
        namespace_id: @project.namespace.id
      }

      # stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs')
      #   .to_return(body: '{ "run_id": "create_run_1" }',
      #              headers: { content_type:
      #                       'application/json' })

      # stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_1/status')
      #   .to_return(body: '{ "run_id": "create_run_1", "state": "COMPLETE" }',
      #              headers: { content_type:
      #                       'application/json' })

      # do not perform completion job as this tests scope does not contain blob storage files
      assert_performed_jobs 0, except: WorkflowExecutionPreparationJob do
        @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params1).execute
      end

      assert_equal 'initial', @workflow_execution.reload.state
    end
  end
end
