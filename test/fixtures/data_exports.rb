# frozen_string_literal: true

FixtureBot.define do
  data_export.export_type { 'sample' }
  data_export.status { 'ready' }
  data_export.created_at { '<%= 1.week.ago %>' }
  data_export.updated_at { '<%= 1.day.ago %>' }
  data_export.user_id { FixtureBot::Key::Uuid.generate(:users, :john_doe) }

  data_export :data_export_one do
    name 'Data Export 1'
    basename 'data-export-1'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sample1),
                                  FixtureBot::Key::Uuid.generate(:samples, :sample2)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :project1_namespace),
                        'attachment_formats' => %w[fasta fastq text csv tsv spreadsheet json genbank unknown]
                      })
    expires_at '<%= 3.days.from_now %>'
    manifest '{"type":"Samples Export","date": "2024-01-01","children":[{"name":"INXT_PRJ_AAAAAAAAAA",' \
             '"type":"folder","irida-next-type":"project","irida-next-name":"Project 1","children":[{"name":' \
             '"INXT_SAM_AAAAAAAAAA","type":"folder","irida-next-type":"sample","irida-next-name":' \
             '"Project 1 Sample 1","children":[{"name":"INXT_ATT_AAAAAAAAAA","type":"folder",' \
             '"irida-next-type":"attachment","children":' \
             '[{"name":"test_file_A.fastq","type":"file","metadata":{"format":"fastq"}}]},{"name":' \
             '"INXT_ATT_AAAAAAAAAB","type":"folder","irida-next-type":"attachment","children":[{"name":' \
             '"test_file_B.fastq","type":"file","metadata":{"format":"fastq"}}]}]}]}]}'
  end

  data_export :data_export_two do
    status 'processing'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sample1),
                                  FixtureBot::Key::Uuid.generate(:samples, :sample2)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :project1_namespace),
                        'attachment_formats' => %w[fasta fastq text csv tsv spreadsheet json genbank unknown]
                      })
    email_notification true
  end

  data_export :data_export_three do
    name 'Data Export 3'
    basename 'data-export-3'
    status 'processing'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sampleB)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :projectA_namespace),
                        'attachment_formats' => %w[fasta fastq text csv tsv spreadsheet json genbank unknown]
                      })
    user :jeff_doe
  end

  data_export :data_export_four do
    name 'Data Export 4'
    basename 'data-export-4'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sampleA),
                                  FixtureBot::Key::Uuid.generate(:samples, :sampleB)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :projectA_namespace),
                        'attachment_formats' => %w[fasta fastq text csv tsv spreadsheet json genbank unknown]
                      })
    expires_at '<%= 5.days.from_now %>'
    user :jeff_doe
  end

  data_export :data_export_five do
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sampleA),
                                  FixtureBot::Key::Uuid.generate(:samples, :sampleB)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :projectA_namespace),
                        'attachment_formats' => %w[fasta fastq text csv tsv spreadsheet json genbank unknown]
                      })
    email_notification true
    expires_at '<%= 5.days.from_now %>'
    user :jeff_doe
  end

  data_export :data_export_six do
    name 'Data Export 6'
    basename 'data-export-6'
    export_type 'analysis'
    status 'processing'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                                 :irida_next_example_completed_with_output)],
                        'analysis_type' => 'user'
                      })
    email_notification true
  end

  data_export :data_export_seven do
    name 'Data Export 7'
    basename 'data-export-7'
    export_type 'analysis'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                                 :irida_next_example_completed_with_output)],
                        'analysis_type' => 'user'
                      })
    email_notification true
    expires_at '<%= 5.days.from_now %>'
    manifest '{"type":"Analysis Export","date":"2024-01-01","children":[{"name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                 :irida_next_example_completed_with_output)}\", " \
             '"type":"folder","irida-next-type":"workflow_execution","irida-next-name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                 :irida_next_example_completed_with_output)}\"," \
             '"children":[{"name":"summary.txt.gz","type":"file"},{"name":"INXT_SAM_AAAAAAAABV","type":"folder",' \
             '"irida-next-type":"sample","irida-next-name":"Sample 44","children":[{"name":"test_file_7.fa",' \
             '"type":"file"}]}]}]}'
  end

  data_export :data_export_eight do
    name 'Data Export 8'
    basename 'data-export-8'
    export_type 'linelist'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sample32)],
                        'linelist_format' => 'csv',
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :project29_namespace),
                        'metadata_fields' => %w[metadatafield1 metadatafield2]
                      })
    email_notification true
    expires_at '<%= 5.days.from_now %>'
  end

  data_export :data_export_nine do
    name 'Data Export 9'
    basename 'data-export-9'
    export_type 'linelist'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sample32),
                                  FixtureBot::Key::Uuid.generate(:samples, :sample33),
                                  FixtureBot::Key::Uuid.generate(:samples, :sample34)],
                        'linelist_format' => 'xlsx',
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:groups, :group_twelve),
                        'metadata_fields' => %w[metadatafield1 non_existant_field metadatafield2]
                      })
    email_notification true
    expires_at '<%= 5.days.from_now %>'
  end

  data_export :data_export_ten do
    name 'Data Export 10'
    basename 'data-export-10'
    status 'processing'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:samples, :sample22)],
                        'namespace_id' => FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                                         :project2_namespace),
                        'attachment_formats' => %w[text fasta]
                      })
    email_notification true
    expires_at '<%= 5.days.from_now %>'
    manifest '{"type":"Samples Export","date": "2024-01-01","children":[{"name":"INXT_PRJ_AAAAAAAAAB",' \
             '"type":"folder","irida-next-type":"project","irida-next-name":"Project 2","children":[{"name":' \
             '"INXT_SAM_AAAAAAAAAV","type":"folder","irida-next-type":"sample","irida-next-name":' \
             '"Project 2 Sample 22","children":[{"name":"INXT_ATT_ABAAAAAAAI","type":"folder","irida-next-type":' \
             '"attachment","children":[{"name":"test_file_14.txt","type":"file","metadata":{"format":"text"}}]},' \
             '{"name":"INXT_ATT_ABAAAAAAAH","type":"folder","irida-next-type":"attachment","children":[{"name":' \
             '"test_file_5.fasta","type":"file","metadata":{"format":"fasta","type":"assembly"}}]}]}]}]}'
  end

  data_export :data_export_eleven do
    name 'Data Export 11'
    basename 'data-export-11'
    export_type 'analysis'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                                 :workflow_execution_completed_shared2)],
                        'analysis_type' => 'user'
                      })
    email_notification true
    user :micha_doe
    expires_at '<%= 5.days.from_now %>'
    manifest '{"type":"Analysis Export","date":"2024-01-01","children":[{"name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions, :workflow_execution_completed_shared2)}\", " \
             '"type":"folder","irida-next-type":"workflow_execution","irida-next-name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions, :workflow_execution_completed_shared2)}\"," \
             '"children":[{"name":"summary.txt.gz","type":"file"},{"name":"INXT_SAM_AAAAAAAABW","type":"folder",' \
             '"irida-next-type":"sample","irida-next-name":"Sample 47","children":[{"name":' \
             '"INXT_SAM_AAAAAAAABW.assembly.fa.gz","type":"file"}]}]}]}'
  end

  data_export :data_export_twelve do
    name 'Data Export 12'
    basename 'data-export-12'
    export_type 'analysis'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                                 :workflow_execution_completed_shared2)],
                        'analysis_type' => 'user'
                      })
    email_notification true
    user :james_doe
    expires_at '<%= 5.days.from_now %>'
    manifest '{"type":"Analysis Export","date":"2024-01-01","children":[{"name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions, :workflow_execution_completed_shared2)}\", " \
             '"type":"folder","irida-next-type":"workflow_execution","irida-next-name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions, :workflow_execution_completed_shared2)}\"," \
             '"children":[{"name":"summary.txt.gz","type":"file"},{"name":"INXT_SAM_AAAAAAAABW","type":"folder",' \
             '"irida-next-type":"sample","irida-next-name":"Sample 47","children":[{"name":' \
             '"INXT_SAM_AAAAAAAABW.assembly.fa.gz","type":"file"}]}]}]}'
  end

  data_export :data_export_thirteen do
    name 'Data Export 13'
    basename 'data-export-13'
    export_type 'analysis'
    export_parameters({
                        'ids' => [FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                                 :workflow_execution_completed_group_shared2)],
                        'analysis_type' => 'user'
                      })
    email_notification true
    user :james_doe
    expires_at '<%= 5.days.from_now %>'
    manifest '{"type":"Analysis Export","date":"2024-01-01","children":[{"name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                 :workflow_execution_completed_group_shared2)}\", " \
             '"type":"folder","irida-next-type":"workflow_execution","irida-next-name":' \
             "\"#{FixtureBot::Key::Uuid.generate(:workflow_executions,
                                                 :workflow_execution_completed_group_shared2)}\"," \
             '"children":[{"name":"summary.txt.gz","type":"file"},{"name":"INXT_SAM_AAAAAAAABW","type":"folder",' \
             '"irida-next-type":"sample","irida-next-name":"Sample 47","children":[{"name":' \
             '"INXT_SAM_AAAAAAAABW.assembly.fa.gz","type":"file"}]}]}]}'
  end
end
