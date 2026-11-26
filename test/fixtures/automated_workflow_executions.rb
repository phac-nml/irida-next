# frozen_string_literal: true

FixtureBot.define do
  # Every row shares the same `workflow_params`/`update_samples`, and most belong to
  # `projectA_namespace`/`jeff_doe` with `email_notification` disabled, so those get default
  # generators; the "valid"/"disabled" rows override namespace/created_by/email_notification
  # explicitly.
  automated_workflow_execution.workflow_params { { 'assembler' => 'stub' } }
  automated_workflow_execution.update_samples { false }
  automated_workflow_execution.namespace_id do
    FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
  end
  automated_workflow_execution.created_by_id { FixtureBot::Key::Uuid.generate(:users, :jeff_doe) }
  automated_workflow_execution.email_notification { false }

  automated_workflow_execution :valid_automated_workflow_execution do
    name 'Valid Automated Workflow Execution'
    namespace :project1_namespace
    created_by :john_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    email_notification true
  end

  automated_workflow_execution :disabled_automated_workflow_execution do
    name 'Disabled Automated Workflow Execution'
    namespace :project1_namespace
    created_by :john_doe
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    email_notification true
    disabled true
  end

  automated_workflow_execution :projectA_automated_workflow_execution_one do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
  end

  automated_workflow_execution :projectA_automated_workflow_execution_two do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.1' })
  end

  automated_workflow_execution :projectA_automated_workflow_execution_three do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' })
  end

  automated_workflow_execution :projectA_automated_workflow_execution_four do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.4' })
  end
end
