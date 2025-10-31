# frozen_string_literal: true

require 'test_helper'

class PipelinesTest < ActiveSupport::TestCase
  test 'disable automated workflow executions after pipeline registration' do
    assert_not Irida::Pipelines.instance.pipelines.empty?
    pipeline = Irida::Pipelines.instance.pipelines['phac-nml/iridanextexample_1.0.0']
    assert_not_nil pipeline
    assert_not pipeline.executable

    automated_workflow_execution = AutomatedWorkflowExecution.find_by(
      "metadata ->> 'pipeline_id' = ? and metadata ->> 'workflow_version' = ?", pipeline.pipeline_id, pipeline.version
    )
    assert_not_nil automated_workflow_execution
    assert_not automated_workflow_execution.disabled

    load Rails.root.join('config/initializers/pipelines.rb')

    assert automated_workflow_execution.reload.disabled
  end

  test 'disable automated workflow executions after pipeline registration when the pipeline has been removed' do
    pipeline_id = 'phac-nml/iridanextexample'
    pipeline_version = '1.0.4'
    assert_not Irida::Pipelines.instance.pipelines.empty?
    assert_nil Irida::Pipelines.instance.pipelines["#{pipeline_id}_#{pipeline_version}"]

    automated_workflow_execution = AutomatedWorkflowExecution.find_by(
      "metadata ->> 'pipeline_id' = ? and metadata ->> 'workflow_version' = ?", pipeline_id, pipeline_version
    )
    assert_not_nil automated_workflow_execution
    assert_not automated_workflow_execution.disabled

    load Rails.root.join('config/initializers/pipelines.rb')

    assert automated_workflow_execution.reload.disabled
  end
end
