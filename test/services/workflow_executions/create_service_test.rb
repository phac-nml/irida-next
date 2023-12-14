# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'prepare new workflow execution' do
      hash1 = {
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

      hash2 = {
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

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, hash1).execute
      @workflow_execution2 = WorkflowExecutions::CreateService.new(@user, hash2).execute

      assert_equal 'new', @workflow_execution.state
      assert_equal 'new', @workflow_execution2.state

      perform_enqueued_jobs(only: WorkflowExecutionPreparationJob)

      assert_equal 'prepared', @workflow_execution.reload.state
      assert_equal 'prepared', @workflow_execution2.reload.state
    end
  end
end
