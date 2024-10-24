# frozen_string_literal: true

require 'test_helper'

class PipelinesTest < ActiveSupport::TestCase
  test 'disable automated workflow executions after pipeline registration' do
    assert_not Irida::Pipelines.instance.available_pipelines.empty?
    pipeline = Irida::Pipelines.instance.available_pipelines['phac-nml/iridanextexample_1.0.0']
    assert_not_nil pipeline
    assert_not pipeline.executable

    automated_workflow_execution = AutomatedWorkflowExecution.find_by(
      "metadata ->> 'workflow_name' = ? and metadata ->> 'workflow_version' = ?", pipeline.name, pipeline.version
    )
    assert_not_nil automated_workflow_execution
    assert_not automated_workflow_execution.disabled

    load Rails.root.join('config/initializers/pipelines.rb')

    assert automated_workflow_execution.reload.disabled
  end
end
