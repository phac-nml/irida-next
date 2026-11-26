# frozen_string_literal: true

FixtureBot.define do
  automated_workflow_execution :valid_automated_workflow_execution do
    name 'Valid Automated Workflow Execution'
    namespace :project1_namespace
    created_by :john_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification true
    update_samples false
  end

  automated_workflow_execution :disabled_automated_workflow_execution do
    name 'Disabled Automated Workflow Execution'
    namespace :project1_namespace
    created_by :john_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification true
    update_samples false
    disabled true
  end

  automated_workflow_execution :projectA_automated_workflow_execution_one do
    namespace :projectA_namespace
    created_by :jeff_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_two do
    namespace :projectA_namespace
    created_by :jeff_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.1' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_three do
    namespace :projectA_namespace
    created_by :jeff_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_four do
    namespace :projectA_namespace
    created_by :jeff_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.4' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end
end
