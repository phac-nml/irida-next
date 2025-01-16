# frozen_string_literal: true

require 'test_helper'

class SubmitWorkflowExecutionMutationTest < ActiveSupport::TestCase
  SUBMIT_WORKFLOW_EXECUTION_MUTATION = <<~GRAPHQL
    mutation(
      $name: String!,
      $project_id: ID!,
      $samples_workflow_executions_attributes: [JSON!]!
      ) {
      submitWorkflowExecution( input:{
        name: $name
        projectId: $project_id
        updateSamples: false
        emailNotification: false
        workflowName: "phac-nml/iridanextexample"
        workflowVersion: "1.0.3"
        workflowParams: {
          assembler: "stub",
          random_seed: 1,
          project_name: "assembly"
        }
        samplesWorkflowExecutionsAttributes: $samples_workflow_executions_attributes
        }) {
        workflowExecution{
          name
          id
        }
        errors{
          message
          path
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @project = projects(:project1)
    @sample = samples(:sample1)
    @attachment1 = attachments(:attachment1)
    @attachment2 = attachments(:attachment2)
  end

  test 'submit workflow execution mutation should work' do
    samples_workflow_executions_attributes = [
      {
        sample_id: @sample.to_global_id.to_s,
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment1.to_global_id.to_s, # rubocop:disable Naming/VariableNumber
          fastq_2: @attachment2.to_global_id.to_s # rubocop:disable Naming/VariableNumber
        }
      }
    ]

    result = IridaSchema.execute(SUBMIT_WORKFLOW_EXECUTION_MUTATION,
                                 context: { current_user: @user },
                                 variables: {
                                   name: 'my_new_workflow_submission',
                                   project_id: @project.to_global_id.to_s,
                                   samples_workflow_executions_attributes:
                                 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['submitWorkflowExecution']
    assert_not_empty data, 'submit workflow execution type should work'
    workflow_execution = data['workflowExecution']
    assert_equal 'my_new_workflow_submission', workflow_execution['name']
  end

  test 'submit workflow execution mutation with non gid project' do
    samples_workflow_executions_attributes = [
      {
        sample_id: @sample.to_global_id.to_s,
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment1.to_global_id.to_s, # rubocop:disable Naming/VariableNumber
          fastq_2: @attachment2.to_global_id.to_s # rubocop:disable Naming/VariableNumber
        }
      }
    ]

    result = IridaSchema.execute(SUBMIT_WORKFLOW_EXECUTION_MUTATION,
                                 context: { current_user: @user },
                                 variables: {
                                   name: 'my_new_workflow_submission',
                                   project_id: 'not a gid',
                                   samples_workflow_executions_attributes:
                                 })

    assert_not_empty result['errors'], 'should have errors.'
    assert_equal 'not a gid is not a valid IRIDA Next ID.', result['errors'][0]['message']
  end

  test 'submit workflow execution mutation with non project gid' do
    samples_workflow_executions_attributes = [
      {
        sample_id: @sample.to_global_id.to_s,
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment1.to_global_id.to_s, # rubocop:disable Naming/VariableNumber
          fastq_2: @attachment2.to_global_id.to_s # rubocop:disable Naming/VariableNumber
        }
      }
    ]

    result = IridaSchema.execute(SUBMIT_WORKFLOW_EXECUTION_MUTATION,
                                 context: { current_user: @user },
                                 variables: {
                                   name: 'my_new_workflow_submission',
                                   project_id: @sample.to_global_id.to_s,
                                   samples_workflow_executions_attributes:
                                 })

    assert_not_empty result['errors'], 'should have errors.'
    assert_equal "#{@sample.to_global_id} is not a valid ID for Project", result['errors'][0]['message']
  end

  test 'submit workflow execution mutation should fail with invalid sample gid' do
    samples_workflow_executions_attributes = [
      {
        sample_id: 'this is not a gid',
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment1.to_global_id.to_s, # rubocop:disable Naming/VariableNumber
          fastq_2: @attachment2.to_global_id.to_s # rubocop:disable Naming/VariableNumber
        }
      }
    ]

    result = IridaSchema.execute(SUBMIT_WORKFLOW_EXECUTION_MUTATION,
                                 context: { current_user: @user },
                                 variables: {
                                   name: 'my_new_workflow_submission',
                                   project_id: @project.to_global_id.to_s,
                                   samples_workflow_executions_attributes:
                                 })

    assert_not_empty result['errors'], 'should have errors.'
    assert_equal 'this is not a gid is not a valid IRIDA Next ID.', result['errors'][0]['message']
  end

  test 'submit workflow execution mutation should fail with non sample gid' do
    samples_workflow_executions_attributes = [
      {
        sample_id: @project.to_global_id.to_s,
        samplesheet_params: {
          sample: @sample.puid,
          fastq_1: @attachment1.to_global_id.to_s, # rubocop:disable Naming/VariableNumber
          fastq_2: @attachment2.to_global_id.to_s # rubocop:disable Naming/VariableNumber
        }
      }
    ]

    result = IridaSchema.execute(SUBMIT_WORKFLOW_EXECUTION_MUTATION,
                                 context: { current_user: @user },
                                 variables: {
                                   name: 'my_new_workflow_submission',
                                   project_id: @project.to_global_id.to_s,
                                   samples_workflow_executions_attributes:
                                 })

    assert_not_empty result['errors'], 'should have errors.'
    assert_equal "#{@project.to_global_id} is not a valid ID for Sample", result['errors'][0]['message']
  end
end
