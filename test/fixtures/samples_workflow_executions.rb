# frozen_string_literal: true

FixtureBot.define do
  samples_workflow_execution :samples_workflow_executions_valid do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_valid, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1, :uuid)}"
                       })
  end

  samples_workflow_execution :samples_workflow_executions_mismatch_file_id do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_valid, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachmentA, :uuid)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_2' => '',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1, :uuid)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_prepared do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_prepared, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_submitted do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_submitted, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_completed do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_completed_2_files do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed_2_files, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment2, :uuid)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_error do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_error, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_canceling do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_canceling, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_canceled do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_canceled, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_running do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_running, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_new do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_new, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_c do
    sample_id ActiveRecord::FixtureSet.identify(:sample41, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_c, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_c do
    sample_id ActiveRecord::FixtureSet.identify(:sample42, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_c, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_d do
    sample_id ActiveRecord::FixtureSet.identify(:sample41, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_d, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_d do
    sample_id ActiveRecord::FixtureSet.identify(:sample42, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_d, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_e do
    sample_id ActiveRecord::FixtureSet.identify(:sample41, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_e, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_e do
    sample_id ActiveRecord::FixtureSet.identify(:sample42, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_e, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_f do
    sample_id ActiveRecord::FixtureSet.identify(:sample41, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_f, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_f do
    sample_id ActiveRecord::FixtureSet.identify(:sample42, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_f, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sampleA_irida_next_example_completing_g do
    sample_id ActiveRecord::FixtureSet.identify(:sampleA, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_g, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAAA3' })
  end

  samples_workflow_execution :sampleB_irida_next_example_completing_g do
    sample_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_g, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAAA4' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_h do
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_h, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_h do
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_h, :uuid)
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample46_irida_next_example_completed_with_output do
    sample_id ActiveRecord::FixtureSet.identify(:sample46, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed_with_output, :uuid)
    samplesheet_params({
                         'sample' => "Sample_#{ActiveRecord::FixtureSet.identify(:sample46, :uuid)}",
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(
                           :samples_workflow_execution_completed_output, :uuid
                         )}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample47_workflow_execution_completed_shared2 do
    sample_id ActiveRecord::FixtureSet.identify(:sample47, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_completed_shared2, :uuid)
    samplesheet_params({
                         'sample' => "Sample_#{ActiveRecord::FixtureSet.identify(:sample47, :uuid)}",
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(
                           :samples_shared_workflow_execution_completed_output, :uuid
                         )}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample47_workflow_execution_completed_group_shared2 do
    sample_id ActiveRecord::FixtureSet.identify(:sample47, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_completed_group_shared2, :uuid)
    samplesheet_params({
                         'sample' => "Sample_#{ActiveRecord::FixtureSet.identify(:sample47, :uuid)}",
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(
                           :samples_group_shared_workflow_execution_completed_output, :uuid
                         )}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_canceled do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_canceled, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_prepared do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_prepared, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_submitted do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_submitted, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_completed do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_completed, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_error do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_error, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_canceling do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_canceling, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_running do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_running, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_new do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared_new, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_submitted do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_submitted, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_completed do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_completed, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_error do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_error, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_canceling do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_canceling, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_canceled do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_canceled, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_running do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_running, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_automated_example_new do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_new, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :end_to_end_example do
    sample_id ActiveRecord::FixtureSet.identify(:sampleEndToEnd, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_end_to_end, :uuid)
    metadata({})
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(
                           :attachmentEndToEndFWD, :uuid
                         )}",
                         'fastq_2' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(
                           :attachmentEndToEndREV, :uuid
                         )}"
                       })
  end

  samples_workflow_execution :sample_completed_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachmentDELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_error_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_error_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachmentDELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_canceled_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_canceled_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachmentDELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_completed_unclean_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed_unclean_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment_completed_unclean_DELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_error_unclean_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_error_unclean_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment_error_unclean_DELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_canceled_unclean_DELETE do
    sample_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_canceled_unclean_DELETE, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment_canceled_unclean_DELETE,
                                                                                                  :uuid)}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :samples_irida_next_example_completing_a do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_completing_a, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1, :uuid)}"
                       })
  end

  samples_workflow_execution :samples_automated_example_prepared do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_example_prepared, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1, :uuid)}"
                       })
  end

  samples_workflow_execution :samples_automated_workflow_execution do
    sample_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:automated_workflow_execution, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify(:attachment1, :uuid)}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_1' do
    sample_id ActiveRecord::FixtureSet.identify('sample_preparation_test_1', :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_three_samples, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZA',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_1',
                                                                                                  :uuid)}",
                         'fastq_2' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_1B',
                                                                                                  :uuid)}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_2' do
    sample_id ActiveRecord::FixtureSet.identify('sample_preparation_test_2', :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_three_samples, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZB',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_2',
                                                                                                  :uuid)}",
                         'fastq_2' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_2B',
                                                                                                  :uuid)}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_3' do
    sample_id ActiveRecord::FixtureSet.identify('sample_preparation_test_3', :uuid)
    workflow_execution_id ActiveRecord::FixtureSet.identify(:irida_next_example_three_samples, :uuid)
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZC',
                         'fastq_1' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_3',
                                                                                                  :uuid)}",
                         'fastq_2' => "gid://irida/Attachment/#{ActiveRecord::FixtureSet.identify('sample_preparation_test_attachment_3B',
                                                                                                  :uuid)}"
                       })
  end
end
