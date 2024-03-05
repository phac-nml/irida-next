# frozen_string_literal: true

require 'test_helper'

class WorfklowExecutionsControllerTest < ActionDispatch::IntegrationTest
  # rubocop:disable Naming/VariableNumber
  setup do
    sign_in users(:john_doe)
    @sample1 = samples(:sample1)
    @attachment1 = attachments(:attachment1)
  end

  test 'should create workflow execution with valid params' do
    assert_difference -> { WorkflowExecution.count } => 1,
                      -> { SamplesWorkflowExecution.count } => 1 do
      post workflow_executions_path(format: :turbo_stream),
           params: {
             workflow_execution: {
               metadata: { workflow_name: 'irida-next-example', workflow_version: '1.0dev' },
               workflow_params: { '-r': 'dev' },
               workflow_type: 'DSL2',
               workflow_type_version: '22.10.7',
               tags: [],
               workflow_engine: 'nextflow',
               workflow_engine_version: '',
               workflow_engine_parameters: { engine: 'nextflow', execute_loc: 'azure' },
               workflow_url: 'https://github.com/phac-nml/iridanextexample',
               samples_workflow_executions_attributes: [
                 {
                   sample_id: @sample1.id,
                   samplesheet_params: {
                     sample: "Sample_#{@sample1.id}",
                     fastq_1: @attachment1.to_global_id,
                     fastq_2: ''
                   }
                 }
               ]
             }
           }

      assert_response :redirect
    end

    created_workflow_execution = WorkflowExecution.last

    assert_equal users(:john_doe), created_workflow_execution.submitter

    assert_equal 1, created_workflow_execution.samples_workflow_executions.count
    assert_equal @sample1, created_workflow_execution.samples_workflow_executions.first.sample
  end

  test 'should cancel a workflow with valid params' do
    workflow_execution = WorkflowExecution.find_by(state: 'prepared',
                                                   metadata: {
                                                     'workflow_name' => 'irida-next-example',
                                                     'workflow_version' => '1.0dev'
                                                   })

    put workflow_execution_cancel_path(workflow_execution, format: :turbo_stream)
    assert_response :success
    assert_equal 'canceling', workflow_execution.reload.state
  end

  # rubocop:enable Naming/VariableNumber
end
