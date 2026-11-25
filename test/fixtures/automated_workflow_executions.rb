# frozen_string_literal: true

FixtureBot.define do
  automated_workflow_execution :valid_automated_workflow_execution do
    name 'Valid Automated Workflow Execution'
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification true
    update_samples false
  end

  automated_workflow_execution :disabled_automated_workflow_execution do
    name 'Disabled Automated Workflow Execution'
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification true
    update_samples false
    disabled true
  end

  automated_workflow_execution :projectA_automated_workflow_execution_one do
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_two do
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.1' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_three do
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end

  automated_workflow_execution :projectA_automated_workflow_execution_four do
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.4' })
    workflow_params({ 'assembler' => 'stub' })
    email_notification false
    update_samples false
  end
end
