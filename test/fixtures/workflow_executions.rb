# frozen_string_literal: true

FixtureBot.define do
  workflow_execution.metadata { { 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.2' } }
  workflow_execution.workflow_params { { 'input' => '/blah/samplesheet.csv', 'outdir' => '/blah/output' } }
  workflow_execution.workflow_engine_parameters { { '-r' => 'dev' } }

  workflow_execution.workflow_type { 'NFL' }
  workflow_execution.workflow_type_version { 'DSL2' }
  workflow_execution.workflow_engine { 'nextflow' }
  workflow_execution.workflow_engine_version { '24.10.3' }
  workflow_execution.namespace_id { FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace) }
  workflow_execution.submitter_id { FixtureBot::Key::Uuid.generate(:users, :john_doe) }
  workflow_execution.workflow_url { 'my_workflow_url' }
  # Anchor the default `created_at`/`updated_at` to a fixed point in the past, relative to whenever
  # fixtures are loaded (rather than relying on Rails' fixture-loader auto-fill, which stamps every
  # un-overridden row with the SAME `Time.now` snapshot). This keeps the default `updated_at desc`
  # index sort deterministic without racing against `Time.current`-stamped rows created during
  # system tests (e.g. freshly submitted workflow executions), which must always sort above
  # fixture data.
  workflow_execution.created_at { '<%= 2.hours.ago %>' }
  workflow_execution.updated_at { '<%= 1.hour.ago %>' }

  workflow_execution :workflow_execution_valid do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.3' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_1'
    name 'workflow_execution_valid'
    # Must sort earlier than the default-anchored `created_at` (2.hours.ago) so it remains
    # john_doe's earliest workflow execution for the default `created_at asc` listing.
    created_at '<%= 3.hours.ago %>'
  end

  workflow_execution :workflow_execution_gasclustering do
    metadata({ 'pipeline_id' => 'phac-nml/gasclustering', 'workflow_version' => '0.4.2' })
    workflow_params({ 'key_a' => 'value_a' })
    workflow_engine_parameters({ '-r' => '0.4.2' })
    run_id 'my_run_id_1'
    submitter :james_doe
    name 'workflow_execution_gasclustering'
  end

  workflow_execution :irida_next_example do
    workflow_params({ 'assembler' => 'stub' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    email_notification true
    cleaned false
    name 'irida_next_example'
  end

  workflow_execution :irida_next_example_non_executable do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' })
    workflow_params({ 'assembler' => 'stub' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    email_notification true
    cleaned false
    name 'irida_next_example_non_executable'
  end

  workflow_execution :irida_next_example_prepared do
    metadata({ 'pipeline_id' => 'irida_next_example_prepared', 'workflow_version' => '1.0dev' })
    workflow_url 'https://github.com/phac-nml/irida_next_example_prepared'
    state 'prepared'
    email_notification true
    cleaned false
    name 'irida_next_example_prepared'
  end

  workflow_execution :irida_next_example_submitted do
    workflow_url 'https://github.com/phac-nml/irida_next_example_prepared'
    run_id 'my_run_id_5'
    state 'submitted'
    cleaned false
    name 'irida_next_example_submitted'
  end

  workflow_execution :irida_next_example_completed do
    workflow_params({ 'input' => '/nextflow/samplesheet_schema.json', 'outdir' => '/blah/output' })
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_6'
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'irida_next_example_completed'
  end

  workflow_execution :irida_next_example_completed_2_files do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_6'
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'irida_next_example_completed_2_files'
  end

  workflow_execution :irida_next_example_completed_unclean do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed_unclean'
    run_id 'my_run_id_6a'
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completed_unclean'
  end

  workflow_execution :irida_next_example_error do
    workflow_url 'https://github.com/phac-nml/irida_next_example_error'
    run_id 'my_run_id_7'
    state 'error'
    cleaned true
    name 'irida_next_example_error'
  end

  workflow_execution :irida_next_example_error_unclean do
    workflow_url 'https://github.com/phac-nml/irida_next_example_error_unclean'
    run_id 'my_run_id_7a'
    state 'error'
    cleaned false
    name 'irida_next_example_error_unclean'
  end

  workflow_execution :irida_next_example_canceling do
    workflow_url 'https://github.com/phac-nml/irida_next_example_canceling'
    run_id 'my_run_id_8'
    state 'canceling'
    cleaned false
    name 'irida_next_example_canceling'
  end

  workflow_execution :irida_next_example_canceled do
    metadata({ 'pipeline_id' => 'irida_next_example_canceled', 'workflow_version' => '1.0dev' })
    workflow_url 'https://github.com/phac-nml/irida_next_example_canceled'
    run_id 'my_run_id_9'
    state 'canceled'
    cleaned true
    name 'irida_next_example_canceled'
  end

  workflow_execution :irida_next_example_canceled_unclean do
    workflow_url 'https://github.com/phac-nml/irida_next_example_canceled_unclean'
    run_id 'my_run_id_9a'
    state 'canceled'
    cleaned false
    name 'irida_next_example_canceled_unclean'
  end

  workflow_execution :irida_next_example_running do
    workflow_url 'https://github.com/phac-nml/irida_next_example_running'
    run_id 'my_run_id_10'
    state 'running'
    cleaned false
    name 'irida_next_example_running'
    # Ensures this row sorts above the default-anchored bulk of fixtures so it reliably
    # appears within the first page of john_doe's default `updated_at desc` listing.
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 30.minutes.ago %>'
  end

  workflow_execution :irida_next_example_new do
    workflow_params({})
    workflow_url 'https://github.com/phac-nml/irida_next_example_new'
    run_id 'my_run_id_12'
    state 'initial'
    cleaned false
    name 'irida_next_example_new'
    # Ensures this row sorts above the default-anchored bulk of fixtures so it reliably
    # appears within the first page of john_doe's default `updated_at desc` listing.
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 30.minutes.ago %>'
  end

  workflow_execution :irida_next_example_completing_a do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_a'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    email_notification true
    cleaned false
    name 'irida_next_example_completing_a'
  end

  workflow_execution :irida_next_example_completing_b do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_b'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completing_b'
  end

  workflow_execution :irida_next_example_completing_c do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_c'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    cleaned false
    update_samples true
    name 'irida_next_example_completing_c'
  end

  workflow_execution :irida_next_example_completing_d do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_d'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completing_d'
  end

  workflow_execution :irida_next_example_completing_e do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_e'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completing_e'
  end

  workflow_execution :irida_next_example_completing_f do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_f'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    email_notification true
    cleaned false
    update_samples false
    name 'irida_next_example_completing_f'
  end

  workflow_execution :irida_next_example_completing_g do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_g'
    submitter :projectA_automation_bot
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    email_notification true
    cleaned false
    update_samples true
    name 'irida_next_example_completing_g'
  end

  workflow_execution :irida_next_example_completing_h do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed'
    run_id 'my_run_id_h'
    submitter :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    state 'completing'
    blob_run_directory 'not a run dir'
    cleaned false
    update_samples true
    name 'irida_next_example_completing_h'
  end

  workflow_execution :irida_next_example_completed_with_output do
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed_with_output'
    run_id 'my_run_id_13'
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project37_namespace)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completed_with_output'
  end

  workflow_execution :automated_workflow_execution do
    workflow_params({ 'assembler' => 'stub', 'project_name' => 'assembly', 'random_seed' => '1' })
    workflow_url 'https://github.com/phac-nml/irida_next_example_completed_with_output'
    run_id 'my_run_id_13'
    submitter :project1_automation_bot
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'automated_workflow_execution'
  end

  (1..25).each do |n|
    workflow_execution(:"workflow_execution#{n}") do
      workflow_params({})
      workflow_url 'https://github.com/phac-nml/irida_next_example_new'
      run_id "my_run_id_#{n}"
      submitter :jane_doe
      namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project33_namespace)
      state 'initial'
      cleaned false
      name "workflow_execution#{n}"
    end
  end

  workflow_execution :workflow_execution_existing do
    workflow_params({ 'assembler' => 'stub', 'project_name' => 'assembly', 'random_seed' => '1' })
    run_id 'my_run_id_1'
    name 'workflow_execution_existing'
  end

  workflow_execution :automated_example_prepared do
    workflow_url 'https://github.com/phac-nml/automated_example_prepared'
    run_id 'my_run_id_4'
    submitter :project1_automation_bot
    state 'prepared'
    email_notification true
    cleaned false
    name 'automated_example_prepared'
  end

  workflow_execution :automated_example_submitted do
    workflow_url 'https://github.com/phac-nml/automated_example_submitted'
    run_id 'my_run_id_5'
    submitter :project1_automation_bot
    state 'submitted'
    cleaned false
    name 'automated_example_submitted'
  end

  workflow_execution :automated_example_completed do
    workflow_url 'https://github.com/phac-nml/automated_example_completed'
    run_id 'my_run_id_6'
    submitter :project1_automation_bot
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'automated_example_completed'
  end

  workflow_execution :automated_example_error do
    workflow_url 'https://github.com/phac-nml/automated_example_error'
    run_id 'my_run_id_7'
    submitter :project1_automation_bot
    state 'error'
    cleaned true
    name 'automated_example_error'
  end

  workflow_execution :automated_example_canceling do
    workflow_url 'https://github.com/phac-nml/automated_example_canceling'
    run_id 'my_run_id_8'
    submitter :project1_automation_bot
    state 'canceling'
    cleaned false
    name 'automated_example_canceling'
  end

  workflow_execution :automated_example_canceled do
    workflow_url 'https://github.com/phac-nml/automated_example_canceled'
    run_id 'my_run_id_9'
    submitter :project1_automation_bot
    state 'canceled'
    cleaned true
    name 'automated_example_canceled'
  end

  workflow_execution :automated_example_running do
    workflow_url 'https://github.com/phac-nml/automated_example_running'
    run_id 'my_run_id_10'
    submitter :project1_automation_bot
    state 'running'
    cleaned false
    name 'automated_example_running'
  end

  workflow_execution :automated_example_new do
    workflow_url 'https://github.com/phac-nml/automated_example_new'
    run_id 'my_run_id_12'
    submitter :project1_automation_bot
    state 'initial'
    cleaned false
    name 'automated_example_new'
  end

  workflow_execution :automated_workflow_execution_existing do
    workflow_params({ 'assembler' => 'stub', 'project_name' => 'assembly', 'random_seed' => '1' })
    run_id 'my_run_id_1'
    submitter :project1_automation_bot
    cleaned false
    name 'automated_example_existing'
  end

  workflow_execution :irida_next_example_end_to_end do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'initial'
    cleaned false
    name 'irida_next_example_end_to_end'
  end

  workflow_execution :irida_next_example_completed_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'irida_next_example_completed_DELETE'
  end

  workflow_execution :irida_next_example_error_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'error'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'irida_next_example_error_DELETE'
  end

  workflow_execution :irida_next_example_canceled_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'canceled'
    blob_run_directory 'not a run dir'
    cleaned true
    name 'irida_next_example_canceled_DELETE'
  end

  workflow_execution :irida_next_example_completed_unclean_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_completed_unclean_DELETE'
  end

  workflow_execution :irida_next_example_error_unclean_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'error'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_error_unclean_DELETE'
  end

  workflow_execution :irida_next_example_canceled_unclean_DELETE do
    workflow_params({ 'assembler' => 'stub', 'random_seed' => 1, 'project_name' => 'assembly' })
    workflow_engine_parameters({ '-r' => '1.0.2' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    run_id 'my_run_id_completed_DELETE'
    submitter :janitor_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_janitor_namespace)
    state 'canceled'
    blob_run_directory 'not a run dir'
    cleaned false
    name 'irida_next_example_canceled_unclean_DELETE'
  end

  workflow_execution :workflow_execution_valid_on_group do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_group_run_id_1'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    name 'workflow_execution_valid_on_group'
  end

  workflow_execution :workflow_execution_shared1 do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_shared_1'
    shared_with_namespace true
    name 'workflow_execution_shared1'
    # Ensures this row sorts above the default-anchored bulk of fixtures so it reliably appears
    # within the first page of the default `updated_at desc` listing. A fixed-offset relative
    # anchor (rather than a `Time.current`-relative offset such as `1.hour.from_now`) avoids racing
    # the fixture loader's auto-fill snapshot, and - critically - never outranks workflow
    # executions that are genuinely created during a test (e.g. freshly submitted via the UI),
    # since those always get a real `Time.current` `updated_at` which is later than any past offset.
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 30.minutes.ago %>'
  end

  workflow_execution :workflow_execution_shared2 do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_shared_2'
    submitter :james_doe
    state 'completed'
    cleaned true
    shared_with_namespace true
    name 'workflow_execution_shared2'
  end

  workflow_execution :workflow_execution_shared3 do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_shared_3'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    shared_with_namespace true
    name 'workflow_execution_shared3'
  end

  workflow_execution :workflow_execution_shared4 do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_shared_4'
    submitter :james_doe
    state 'running'
    cleaned false
    shared_with_namespace true
    name 'workflow_execution_shared4'
  end

  workflow_execution :workflow_execution_completed_shared1 do
    workflow_url 'https://github.com/phac-nml/irida_next_shared_example_completed_with_output'
    run_id 'my_run_id_shared_1'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    shared_with_namespace true
    name 'irida_next_user_shared_example_completed_with_output'
  end

  workflow_execution :workflow_execution_completed_shared2 do
    workflow_url 'https://github.com/phac-nml/irida_next_shared_example_completed_with_output'
    run_id 'my_run_id_shared_2'
    submitter :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    shared_with_namespace true
    name 'irida_next_member_shared_example_completed_with_output'
  end

  workflow_execution :workflow_execution_group_shared1 do
    workflow_params({ 'assembler' => 'stub', 'project_name' => 'assembly', 'random_seed' => '1' })
    run_id 'my_run_id_group_shared_1'
    submitter :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    shared_with_namespace true
    name 'Group Shared Example1'
  end

  workflow_execution :workflow_execution_group_shared2 do
    workflow_params({ 'assembler' => 'stub', 'project_name' => 'assembly', 'random_seed' => '1' })
    run_id 'my_run_id_group_shared_2'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    shared_with_namespace true
    name 'Group Shared Example2'
  end

  workflow_execution :workflow_execution_group_shared3 do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared_3'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    shared_with_namespace true
    name 'Group Shared Example3'
  end

  workflow_execution :workflow_execution_completed_group_shared1 do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.3' })
    workflow_url 'https://github.com/phac-nml/irida_next_shared_example_completed_with_output'
    run_id 'my_run_id_group_shared_1'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    shared_with_namespace true
    name 'irida_next_user_group_shared_example_completed_with_output'
  end

  workflow_execution :workflow_execution_completed_group_shared2 do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.3' })
    workflow_url 'https://github.com/phac-nml/irida_next_shared_example_completed_with_output'
    run_id 'my_run_id_group_shared_2'
    submitter :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
    state 'completed'
    blob_run_directory 'not a run dir'
    cleaned false
    shared_with_namespace true
    name 'irida_next_user_group_shared_example_completed_with_output'
  end

  workflow_execution :workflow_execution_group_shared_new do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'initial'
    cleaned false
    shared_with_namespace true
    name 'Group Shared New'
  end

  workflow_execution :workflow_execution_group_shared_prepared do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'prepared'
    cleaned false
    shared_with_namespace true
    name 'Group Shared Prepared'
  end

  workflow_execution :workflow_execution_group_shared_submitted do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'submitted'
    cleaned false
    shared_with_namespace true
    name 'Group Shared Submitted'
  end

  workflow_execution :workflow_execution_group_shared_completed do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'completed'
    cleaned true
    shared_with_namespace true
    name 'Group Shared Completed'
  end

  workflow_execution :workflow_execution_group_shared_running do
    metadata({ 'pipeline_id' => 'wn1', 'workflow_version' => 'wv1' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'running'
    cleaned false
    shared_with_namespace true
    name 'Group Shared Running'
  end

  workflow_execution :workflow_execution_group_shared_error do
    workflow_url 'https://github.com/phac-nml/group_workflow_example_error'
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'error'
    cleaned true
    shared_with_namespace true
    name 'workflow_execution_group_shared_error'
  end

  workflow_execution :workflow_execution_group_shared_canceling do
    workflow_url 'https://github.com/phac-nml/workflow_execution_group_shared_canceling'
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'canceling'
    cleaned false
    shared_with_namespace true
    name 'workflow_execution_group_shared_canceling'
  end

  workflow_execution :workflow_execution_group_shared_canceled do
    workflow_url 'https://github.com/phac-nml/group_workflow_example_canceled'
    run_id 'my_run_id_group_shared'
    submitter :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    state 'canceled'
    cleaned true
    shared_with_namespace true
    name 'Group Shared Canceled'
  end

  workflow_execution :workflow_execution_missing_namespace do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.3' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'my_run_id_1'
    submitter :steve_doe
    namespace_id 'This namespace has been deleted'
    name 'workflow_execution_valid'
  end

  workflow_execution :workflow_execution_missing_run_id do
    metadata({ 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.3' })
    workflow_params({ 'key_a' => 'value_a' })
    run_id nil
    submitter :steve_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :steve_doe_namespace)
    name 'workflow_execution_valid'
  end

  workflow_execution :workflow_execution_with_metadata_dates do
    metadata({
               'pipeline_id' => 'phac-nml/iridanextexample',
               'workflow_version' => '1.0.3',
               'start_date' => '2024-01-15',
               'end_date' => '2024-01-20',
               'sample_count' => '10',
               'file_size' => '1024.5'
             })
    workflow_params({ 'key_a' => 'value_a' })
    run_id 'metadata_date_run_1'
    state 'completed'
    name 'workflow_with_metadata_dates'
  end

  workflow_execution :workflow_execution_with_metadata_dates2 do
    metadata({ 'pipeline_id' => 'phac-nml/gasclustering', 'workflow_version' => '0.5.0', 'start_date' => '2024-02-01',
               'end_date' => '2024-02-10', 'sample_count' => '25', 'file_size' => '2048.75' })
    workflow_params({ 'key_b' => 'value_b' })
    run_id 'metadata_date_run_2'
    state 'completed'
    name 'workflow_with_metadata_dates_2'
  end

  workflow_execution :workflow_execution_with_null_metadata do
    metadata({ 'pipeline_id' => 'phac-nml/test' })
    workflow_params({ 'key_c' => 'value_c' })
    run_id 'null_metadata_run'
    state 'initial'
    name 'workflow_with_null_metadata'
  end

  workflow_execution :workflow_execution_with_special_chars do
    metadata({ 'pipeline_id' => 'phac-nml/special-chars', 'workflow_version' => '1.0.0',
               'custom_field' => 'value_with_%_and_underscore' })
    workflow_params({ 'key_d' => 'value_d' })
    run_id 'special_chars_run'
    state 'running'
    name 'workflow_with_special_chars'
  end

  workflow_execution :irida_next_example_three_samples do
    workflow_params({ 'assembler' => 'stub' })
    workflow_url 'https://github.com/phac-nml/iridanextexample'
    submitter :user32
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :user32_project1_namespace)
    email_notification true
    cleaned false
    name 'irida_next_example_three_samples'
  end
end
