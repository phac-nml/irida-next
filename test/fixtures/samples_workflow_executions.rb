# frozen_string_literal: true

FixtureBot.define do
  samples_workflow_execution.samplesheet_params do
    {
      'sample' => 'INXT_SAM_AAAAAAAAAA',
      'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments, :attachment1)}",
      'fastq_2' => ''
    }
  end

  samples_workflow_execution :samples_workflow_executions_valid do
    sample :sample1
    workflow_execution :workflow_execution_valid
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}"
                       })
  end

  samples_workflow_execution :samples_workflow_executions_mismatch_file_id do
    sample :sample1
    workflow_execution :workflow_execution_valid
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachmentA)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example do
    sample :sample1
    workflow_execution :irida_next_example
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_2' => '',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_prepared do
    sample :sample1
    workflow_execution :irida_next_example_prepared
  end

  samples_workflow_execution :sample1_irida_next_example_submitted do
    sample :sample1
    workflow_execution :irida_next_example_submitted
  end

  samples_workflow_execution :sample1_irida_next_example_completed do
    sample :sample1
    workflow_execution :irida_next_example_completed
  end

  samples_workflow_execution :sample1_irida_next_example_completed_2_files do
    sample :sample1
    workflow_execution :irida_next_example_completed_2_files
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}",
                         'fastq_2' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment2)}"
                       })
  end

  samples_workflow_execution :sample1_irida_next_example_error do
    sample :sample1
    workflow_execution :irida_next_example_error
  end

  samples_workflow_execution :sample1_irida_next_example_canceling do
    sample :sample1
    workflow_execution :irida_next_example_canceling
  end

  samples_workflow_execution :sample1_irida_next_example_canceled do
    sample :sample1
    workflow_execution :irida_next_example_canceled
  end

  samples_workflow_execution :sample1_irida_next_example_running do
    sample :sample1
    workflow_execution :irida_next_example_running
  end

  samples_workflow_execution :sample1_irida_next_example_new do
    sample :sample1
    workflow_execution :irida_next_example_new
  end

  samples_workflow_execution :sample41_irida_next_example_completing_c do
    sample :sample41
    workflow_execution :irida_next_example_completing_c
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_c do
    sample :sample42
    workflow_execution :irida_next_example_completing_c
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_d do
    sample :sample41
    workflow_execution :irida_next_example_completing_d
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_d do
    sample :sample42
    workflow_execution :irida_next_example_completing_d
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_e do
    sample :sample41
    workflow_execution :irida_next_example_completing_e
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_e do
    sample :sample42
    workflow_execution :irida_next_example_completing_e
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_f do
    sample :sample41
    workflow_execution :irida_next_example_completing_f
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_f do
    sample :sample42
    workflow_execution :irida_next_example_completing_f
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sampleA_irida_next_example_completing_g do
    sample :sampleA
    workflow_execution :irida_next_example_completing_g
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAAA3' })
  end

  samples_workflow_execution :sampleB_irida_next_example_completing_g do
    sample :sampleB
    workflow_execution :irida_next_example_completing_g
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAAA4' })
  end

  samples_workflow_execution :sample41_irida_next_example_completing_h do
    workflow_execution :irida_next_example_completing_h
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABQ' })
  end

  samples_workflow_execution :sample42_irida_next_example_completing_h do
    workflow_execution :irida_next_example_completing_h
    samplesheet_params({ 'sample' => 'INXT_SAM_AAAAAAAABR' })
  end

  samples_workflow_execution :sample46_irida_next_example_completed_with_output do
    sample :sample46
    workflow_execution :irida_next_example_completed_with_output
    sample_id = FixtureBot::Key::Uuid.generate(:samples, :sample46)
    fastq_1_id = FixtureBot::Key::Uuid.generate(:'active_storage/attachments',
                                                :samples_workflow_execution_completed_output)
    samplesheet_params({
                         'sample' => "Sample_#{sample_id}",
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample47_workflow_execution_completed_shared2 do
    sample :sample47
    workflow_execution :workflow_execution_completed_shared2
    sample_id = FixtureBot::Key::Uuid.generate(:samples, :sample47)
    fastq_1_id = FixtureBot::Key::Uuid.generate(:'active_storage/attachments',
                                                :samples_shared_workflow_execution_completed_output)
    samplesheet_params({
                         'sample' => "Sample_#{sample_id}",
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample47_workflow_execution_completed_group_shared2 do
    sample :sample47
    workflow_execution :workflow_execution_completed_group_shared2
    sample_id = FixtureBot::Key::Uuid.generate(:samples, :sample47)
    fastq_1_id = FixtureBot::Key::Uuid.generate(:'active_storage/attachments',
                                                :samples_group_shared_workflow_execution_completed_output)
    samplesheet_params({
                         'sample' => "Sample_#{sample_id}",
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_canceled do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_canceled
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_prepared do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_prepared
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_submitted do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_submitted
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_completed do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_completed
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_error do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_error
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_canceling do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_canceling
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_running do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_running
  end

  samples_workflow_execution :sample1_workflow_execution_group_shared_new do
    sample :sample1
    workflow_execution :workflow_execution_group_shared_new
  end

  samples_workflow_execution :sample1_automated_example_submitted do
    sample :sample1
    workflow_execution :automated_example_submitted
  end

  samples_workflow_execution :sample1_automated_example_completed do
    sample :sample1
    workflow_execution :automated_example_completed
  end

  samples_workflow_execution :sample1_automated_example_error do
    sample :sample1
    workflow_execution :automated_example_error
  end

  samples_workflow_execution :sample1_automated_example_canceling do
    sample :sample1
    workflow_execution :automated_example_canceling
  end

  samples_workflow_execution :sample1_automated_example_canceled do
    sample :sample1
    workflow_execution :automated_example_canceled
  end

  samples_workflow_execution :sample1_automated_example_running do
    sample :sample1
    workflow_execution :automated_example_running
  end

  samples_workflow_execution :sample1_automated_example_new do
    sample :sample1
    workflow_execution :automated_example_new
  end

  samples_workflow_execution :end_to_end_example do
    sample :sampleEndToEnd
    workflow_execution :irida_next_example_end_to_end
    metadata({})
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachmentEndToEndFWD)
    fastq_2_id = FixtureBot::Key::Uuid.generate(:attachments, :attachmentEndToEndREV)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => "gid://irida/Attachment/#{fastq_2_id}"
                       })
  end

  samples_workflow_execution :sample_completed_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_completed_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachmentDELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_error_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_error_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachmentDELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_canceled_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_canceled_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachmentDELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_completed_unclean_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_completed_unclean_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachment_completed_unclean_DELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_error_unclean_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_error_unclean_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachment_error_unclean_DELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :sample_canceled_unclean_DELETE do
    sample :sampleDELETE
    workflow_execution :irida_next_example_canceled_unclean_DELETE
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, :attachment_canceled_unclean_DELETE)
    samplesheet_params({
                         'sample' => 'INXT_SAM_ABAAAAAAAB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => ''
                       })
  end

  samples_workflow_execution :samples_irida_next_example_completing_a do
    sample :sample1
    workflow_execution :irida_next_example_completing_a
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}"
                       })
  end

  samples_workflow_execution :samples_automated_example_prepared do
    sample :sample1
    workflow_execution :automated_example_prepared
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}"
                       })
  end

  samples_workflow_execution :samples_automated_workflow_execution do
    sample :sample1
    workflow_execution :automated_workflow_execution
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAAA',
                         'fastq_1' => "gid://irida/Attachment/#{FixtureBot::Key::Uuid.generate(:attachments,
                                                                                               :attachment1)}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_1' do
    sample 'sample_preparation_test_1'
    workflow_execution :irida_next_example_three_samples
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_1')
    fastq_2_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_1B')
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZA',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => "gid://irida/Attachment/#{fastq_2_id}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_2' do
    sample 'sample_preparation_test_2'
    workflow_execution :irida_next_example_three_samples
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_2')
    fastq_2_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_2B')
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZB',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => "gid://irida/Attachment/#{fastq_2_id}"
                       })
  end

  samples_workflow_execution 'samples_workflow_executions_preparation_test_3' do
    sample 'sample_preparation_test_3'
    workflow_execution :irida_next_example_three_samples
    fastq_1_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_3')
    fastq_2_id = FixtureBot::Key::Uuid.generate(:attachments, 'sample_preparation_test_attachment_3B')
    samplesheet_params({
                         'sample' => 'INXT_SAM_AAAAAAAAZC',
                         'fastq_1' => "gid://irida/Attachment/#{fastq_1_id}",
                         'fastq_2' => "gid://irida/Attachment/#{fastq_2_id}"
                       })
  end
end
