# frozen_string_literal: true

FixtureBot.define do
  {
    project1_namespace_sample_transfer_activity_extended_details: {
      activity: :project1_namespace_sample_transfer,
      extended_detail: :project1_namespace_sample_transfer_extended_details,
      activity_type: 'sample_transfer'
    },
    project2_namespace_sample_transferred_from_project1_activity_extended_details: {
      activity: :project2_namespace_sample_transferred_from_project1,
      extended_detail: :project1_namespace_sample_transfer_extended_details,
      activity_type: 'sample_transfer'
    },
    project1_namespace_sample_clone_activity_extended_details: {
      activity: :project1_namespace_sample_clone,
      extended_detail: :project1_namespace_sample_clone_extended_details,
      activity_type: 'sample_clone'
    },
    project2_namespace_sample_cloned_from_project1_activity_extended_details: {
      activity: :project2_namespace_sample_cloned_from_project1,
      extended_detail: :project1_namespace_sample_clone_extended_details,
      activity_type: 'sample_clone'
    },
    project1_namespace_workflow_execution_destroy_activity_extended_details: {
      activity: :project1_namespace_workflow_execution_destroy,
      extended_detail: :project1_namespace_workflow_execution_destroy_extended_details,
      activity_type: 'workflow_execution_destroy'
    },
    project1_namespace_import_sample_activity_extended_details: {
      activity: :project1_namespace_sample_import_create,
      extended_detail: :project1_namespace_import_sample_create_extended_details,
      activity_type: 'project_import_samples'
    },
    group1_namespace_import_sample_activity_extended_details: {
      activity: :group1_sample_import_create,
      extended_detail: :group1_namespace_import_sample_create_extended_details,
      activity_type: 'group_import_samples'
    },
    group1_namespace_sample_destroy_activity_extended_details: {
      activity: :group1_sample_destroy,
      extended_detail: :group1_namespace_sample_destroy_extended_details,
      activity_type: 'group_samples_destroy'
    },
    group_sample_transfer_sample_transfer_activity_extended_details: {
      activity: :group_sample_transfer_sample_transfer,
      extended_detail: :group_sample_transfer_sample_transfer_extended_details,
      activity_type: 'group_sample_transfer'
    },
    project_group_sample_transfer_sample_transfer_activity_extended_details: {
      activity: :project_group_sample_transfer_sample_transfer,
      extended_detail: :project_group_sample_transfer_sample_transfer_extended_details,
      activity_type: 'sample_transfer'
    },
    project_group_sample_transfer_target_sample_transfer_activity_extended_details: {
      activity: :project_group_sample_transfer_target_sample_transfer,
      extended_detail: :project_group_sample_transfer_sample_transfer_extended_details,
      activity_type: 'sample_transfer'
    }
  }.each do |record_name, attrs|
    activity_extended_detail(record_name) do
      activity attrs[:activity]
      extended_detail attrs[:extended_detail]
      activity_type attrs[:activity_type]
    end
  end
end
