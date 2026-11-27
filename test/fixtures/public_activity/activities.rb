# frozen_string_literal: true

FixtureBot.define do
  activity.trackable_type { 'Namespace' }

  activity :project1_namespace_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.create'
    parameters({})
  end

  activity :project2_namespace_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    key 'namespaces_project_namespace.create'
    parameters({})
  end

  activity :project1_namespace_member_james_doe_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.member.create'
    parameters({ 'member_email' => 'james.doe@localhost', 'action' => 'member_create' })
  end

  activity :project1_namespace_member_ryan_doe_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.member.create'
    parameters({ 'member_email' => 'ryan.doe@localhost', 'action' => 'member_create' })
  end

  activity :project1_namespace_sample_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.samples.create'
    parameters({
                 'sample_id' => FixtureBot::Key::Uuid.generate(:samples, :sample1),
                 'sample_puid' => 'INXT_SAM_AAAAAAAAAA',
                 'action' => 'sample_create'
               })
  end

  activity :project1_namespace_sample_clone do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.samples.clone'
    parameters({
                 'target_project_puid' => 'INXT_PRJ_AAAAAAAAAB',
                 'target_project' => FixtureBot::Key::Uuid.generate(:projects, :project2),
                 'cloned_samples_count' => 1,
                 'action' => 'sample_clone'
               })
  end

  activity :project1_namespace_metadata_template_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.metadata_template.create'
    parameters({
                 'template_id' => FixtureBot::Key::Uuid.generate(:metadata_templates, :valid_metadata_template),
                 'template_name' => 'Valid Template',
                 'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                  :project1_namespace),
                 'action' => 'metadata_template_create'
               })
  end

  activity :project2_namespace_sample_cloned_from_project1 do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    key 'namespaces_project_namespace.samples.cloned_from'
    parameters({
                 'source_project_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 'source_project' => FixtureBot::Key::Uuid.generate(:projects, :project1),
                 'cloned_samples_count' => 1,
                 'action' => 'sample_clone'
               })
  end

  activity :project1_namespace_sample_transfer do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.samples.transfer'
    parameters({
                 'target_project_puid' => 'INXT_PRJ_AAAAAAAAAB',
                 'target_project' => FixtureBot::Key::Uuid.generate(:projects, :project2),
                 'transferred_samples_count' => 1,
                 'action' => 'sample_transfer'
               })
  end

  activity :project2_namespace_sample_transferred_from_project1 do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    key 'namespaces_project_namespace.samples.transferred_from'
    parameters({
                 'source_project_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 'source_project' => FixtureBot::Key::Uuid.generate(:projects, :project1),
                 'transferred_samples_count' => 1,
                 'action' => 'sample_transfer'
               })
  end

  activity :project1_namespace_automated_workflow_execution_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.automated_pipeline.create'
    parameters({
                 'automated_pipeline_id' => FixtureBot::Key::Uuid.generate(:automated_workflow_executions,
                                                                           :valid_automated_workflow_execution),
                 'action' => 'automated_pipeline_create'
               })
  end

  activity :project1_namespace_automated_workflow_execution_launch do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'workflow_execution.automated_workflow.launch'
    parameters({
                 'workflow_id' => FixtureBot::Key::Uuid.generate(:workflow_executions, :workflow_execution_valid),
                 'workflow_name' => '',
                 'sample_id' => FixtureBot::Key::Uuid.generate(:samples, :sample1),
                 'sample_puid' => 'INXT_SAM_AAAAAAAAAA'
               })
  end

  activity :project1_namespace_sample_attachment_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.samples.attachment.create'
    parameters({
                 'sample_puid' => 'INXT_SAM_AAAAAAAAAA',
                 'sample_id' => FixtureBot::Key::Uuid.generate(:samples, :sample1),
                 'action' => 'attachment_create'
               })
  end

  activity :project1_shared_w_group_charlie do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.namespace_group_link.create'
    parameters({
                 'group_name' => 'Group Charlie',
                 'group_puid' => 'INXT_GRP_AAAAAAAAAU',
                 'namespace_name' => 'Project 1',
                 'namespace_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 # NOTE: faithfully reproduces a pre-existing typo in the original fixture, where
                 # `namespace_type: project',` (missing opening quote) parses as the literal
                 # string "project'" (with a trailing apostrophe) rather than "project".
                 'namespace_type' => "project'",
                 'action' => 'group_link_create'
               })
  end

  activity :group_charlie_shared_by_project1 do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_charlie)
    key 'group.namespace_group_link.created'
    parameters({
                 'group_name' => 'Group Charlie',
                 'group_puid' => 'INXT_GRP_AAAAAAAAAU',
                 'namespace_name' => 'Project 1',
                 'namespace_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 'namespace_type' => 'project',
                 'action' => 'group_link_created'
               })
  end

  activity :project1_namespace_transfer do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.transfer'
    parameters({
                 # NOTE: faithfully reproduces a pre-existing bug in the original fixture:
                 # `ActiveRecord::FixtureSet.identify(label, :name)` does NOT look up the
                 # referenced record's `name` attribute -- the only recognized column type is
                 # `:uuid` (producing a UUID); any other value (including `:name`) falls through
                 # to the default branch, which returns a `Zlib.crc32` integer hash of the label.
                 'project_name' => ActiveRecord::FixtureSet.identify(:project1_namespace, :name),
                 'old_namespace' => ActiveRecord::FixtureSet.identify(:group_one, :name),
                 'new_namespace' => ActiveRecord::FixtureSet.identify(:group_two, :name),
                 'action' => 'project_namespace_transfer'
               })
  end

  activity :group1_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.create'
    parameters({})
  end

  activity :group1_subgroup_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.subgroups.create'
    parameters({
                 'created_group_id' => FixtureBot::Key::Uuid.generate(:groups, :subgroup1),
                 'created_group_puid' => 'INXT_GRP_AAAAAAAAAB',
                 'action' => 'group_subgroup_create'
               })
  end

  activity :group1_project_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.projects.create'
    parameters({
                 'project_id' => FixtureBot::Key::Uuid.generate(:projects, :project1),
                 'project_puid' => 'INXT_PRJ_AAAAAAAAAA'
               })
  end

  activity :group1_project_transfer_out do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.projects.transfer_out'
    parameters({
                 'project_id' => FixtureBot::Key::Uuid.generate(:projects, :project1),
                 'project_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 'old_namespace' => 'INXT_GRP_AAAAAAAAAA',
                 'new_namespace' => 'INXT_GRP_AAAAAAAAAC',
                 'action' => 'project_namespace_transfer'
               })
  end

  activity :group1_project_transfer_in do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.projects.transfer_in'
    parameters({
                 'project_id' => FixtureBot::Key::Uuid.generate(:projects, :project1),
                 'project_puid' => 'INXT_PRJ_AAAAAAAAAA',
                 'old_namespace' => 'INXT_GRP_AAAAAAAAAC',
                 'new_namespace' => 'INXT_GRP_AAAAAAAAAA',
                 'action' => 'project_namespace_transfer'
               })
  end

  activity :group1_member_james_doe_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.member.create'
    parameters({ 'member_email' => 'james.doe@localhost', 'action' => 'member_create' })
  end

  activity :group_one_metadata_template_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.metadata_template.create'
    parameters({
                 'template_id' => FixtureBot::Key::Uuid.generate(:metadata_templates, :valid_group_metadata_template),
                 'template_name' => 'Valid Group Template',
                 'namespace_id' => FixtureBot::Key::Uuid.generate(:groups, :group_one),
                 'action' => 'metadata_template_create'
               })
  end

  activity :group1_shared_w_david_doe_group_four do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.namespace_group_link.create'
    parameters({
                 'group_name' => 'Group 4',
                 'group_puid' => 'INXT_GRP_AAAAAAAAAF',
                 'namespace_name' => 'Group 1',
                 'namespace_puid' => 'INXT_GRP_AAAAAAAAAA',
                 # NOTE: faithfully reproduces a pre-existing typo in the original fixture, where
                 # `namespace_type: group',` (missing opening quote) parses as the literal string
                 # "group'" (with a trailing apostrophe) rather than "group".
                 'namespace_type' => "group'",
                 'action' => 'group_link_create'
               })
  end

  activity :david_doe_group_four_shared_by_group1 do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :david_doe_group_four)
    key 'group.namespace_group_link.created'
    parameters({
                 'group_name' => 'Group 4',
                 'group_puid' => 'INXT_GRP_AAAAAAAAAF',
                 'namespace_name' => 'Group 1',
                 'namespace_puid' => 'INXT_GRP_AAAAAAAAAA',
                 'namespace_type' => 'group',
                 'action' => 'group_link_created'
               })
  end

  activity :project1_namespace_sample_import_create do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.import_samples.create'
    parameters({ 'imported_samples_count' => 1, 'action' => 'project_import_samples' })
  end

  activity :group1_sample_import_create do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.import_samples.create'
    parameters({ 'imported_samples_count' => 2, 'action' => 'group_import_samples' })
  end

  activity :project1_namespace_workflow_execution_destroy do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    key 'namespaces_project_namespace.workflow_executions.destroy'
    parameters({ 'workflow_executions_deleted_count' => 3, 'action' => 'workflow_execution_destroy' })
  end

  activity :group_sample_transfer_sample_transfer do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_transfer)
    key 'group.samples.transfer'
    parameters({ 'transferred_samples_count' => 3, 'action' => 'group_sample_transfer' })
  end

  activity :project_group_sample_transfer_sample_transfer do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_group_sample_transfer_namespace)
    key 'namespaces_project_namespace.samples.transfer'
    parameters({
                 'transferred_samples_count' => 3,
                 'target_project_puid' => 'INXT_PRJ_AAAAAAAACD',
                 'target_project' => FixtureBot::Key::Uuid.generate(:projects, :projectGroupSampleTransferTarget),
                 'action' => 'sample_transfer'
               })
  end

  activity :project_group_sample_transfer_target_sample_transfer do
    trackable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_group_sample_transfer_target_namespace)
    key 'namespaces_project_namespace.import_samples.create'
    parameters({
                 'transferred_samples_count' => 3,
                 'source_project_puid' => 'INXT_PRJ_AAAAAAAACC',
                 'source_project' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                    :project_group_sample_transfer_namespace),
                 'action' => 'sample_transfer'
               })
  end

  activity :group1_sample_destroy do
    trackable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    key 'group.samples.destroy'
    parameters({ 'samples_deleted_count' => 2, 'action' => 'group_samples_destroy' })
  end
end
