# frozen_string_literal: true

require 'active_storage_test_case'

module WorkflowExecutions
  class CompletionServiceTest < ActiveStorageTestCase
    def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # normal/
      # get a new secure token for each workflow execution
      @workflow_execution_completing = workflow_executions(:irida_next_example_completing_a)
      blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_completing.blob_run_directory = blob_run_directory_a

      # create file blobs
      @normal_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/iridanext.output.json',
        blob_run_directory: blob_run_directory_a,
        gzip: true
      )
      @normal_output_summary_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/summary.txt',
        blob_run_directory: blob_run_directory_a
      )

      # no_files/
      # get a new secure token for each workflow execution
      @workflow_execution_no_files = workflow_executions(:irida_next_example_completing_b)
      blob_run_directory_b = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_no_files.blob_run_directory = blob_run_directory_b

      # create file blobs
      @no_files_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/no_files/iridanext.output.json',
        blob_run_directory: blob_run_directory_b,
        gzip: true
      )

      # normal2/
      # get a new secure token for each workflow execution
      @workflow_execution_with_samples = workflow_executions(:irida_next_example_completing_c)
      blob_run_directory_c = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_with_samples.blob_run_directory = blob_run_directory_c

      # create file blobs
      @normal2_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/iridanext.output.json',
        blob_run_directory: blob_run_directory_c,
        gzip: true
      )
      @normal2_output_summary_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/summary.txt',
        blob_run_directory: blob_run_directory_c
      )
      @normal2_output_analysis1_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis1.txt',
        blob_run_directory: blob_run_directory_c
      )
      @normal2_output_analysis2_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis2.txt',
        blob_run_directory: blob_run_directory_c
      )
      @normal2_output_analysis3_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis3.txt',
        blob_run_directory: blob_run_directory_c
      )

      # normal2/ without update_samples
      # get a new secure token for each workflow execution
      @workflow_execution_with_samples_without_update_samples = workflow_executions(:irida_next_example_completing_f)
      blob_run_directory_f = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_with_samples_without_update_samples.blob_run_directory = blob_run_directory_f

      # create file blobs
      @normal2_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/iridanext.output.json',
        blob_run_directory: blob_run_directory_f,
        gzip: true
      )
      @normal2_output_summary_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/summary.txt',
        blob_run_directory: blob_run_directory_f
      )
      @normal2_output_analysis1_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis1.txt',
        blob_run_directory: blob_run_directory_f
      )
      @normal2_output_analysis2_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis2.txt',
        blob_run_directory: blob_run_directory_f
      )
      @normal2_output_analysis3_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal2/analysis3.txt',
        blob_run_directory: blob_run_directory_f
      )

      # missing_entry/
      # get a new secure token for each workflow execution
      @workflow_execution_missing_entry = workflow_executions(:irida_next_example_completing_d)
      blob_run_directory_d = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_missing_entry.blob_run_directory = blob_run_directory_d

      # create file blobs
      @missing_entry_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/missing_entry/iridanext.output.json',
        blob_run_directory: blob_run_directory_d,
        gzip: true
      )
      @missing_entry_output_summary_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/missing_entry/summary.txt',
        blob_run_directory: blob_run_directory_d
      )
      @missing_entry_output_analysis3_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/missing_entry/analysis3.txt',
        blob_run_directory: blob_run_directory_d
      )

      # normal3/
      # get a new secure token for each workflow execution
      @workflow_execution_with_complex_metadata = workflow_executions(:irida_next_example_completing_e)
      blob_run_directory_e = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_with_complex_metadata.blob_run_directory = blob_run_directory_e

      # create file blobs
      @normal3_output_json_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal3/iridanext.output.json',
        blob_run_directory: blob_run_directory_e,
        gzip: true
      )
      @normal3_output_summary_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal3/summary.txt',
        blob_run_directory: blob_run_directory_e
      )
      @normal3_output_analysis1_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal3/analysis1.txt',
        blob_run_directory: blob_run_directory_e
      )
      @normal3_output_analysis2_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal3/analysis2.txt',
        blob_run_directory: blob_run_directory_e
      )
      @normal3_output_analysis3_file_blob = make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal3/analysis3.txt',
        blob_run_directory: blob_run_directory_e
      )

      # associated test samples
      @sample41 = samples(:sample41)
      @sample42 = samples(:sample42)
    end

    test 'complete completing workflow_execution' do
      workflow_execution = @workflow_execution_completing

      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_a', workflow_execution.run_id
      assert_equal 1, workflow_execution.outputs.count
      # original file blob should not be the same as the output file blob, but contain the same file
      output_summary_file = workflow_execution.outputs[0]
      assert_not_equal @normal_output_summary_file_blob.id, output_summary_file.id
      assert_equal @normal_output_summary_file_blob.filename, output_summary_file.filename
      assert_equal @normal_output_summary_file_blob.checksum, output_summary_file.file.checksum

      assert_equal 'completed', workflow_execution.state

      assert workflow_execution.email_notification
      assert_enqueued_emails 1
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution]
    end

    test 'finalize non complete workflow_execution' do
      workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'completing', workflow_execution.state

      assert_not WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_not_equal 'completing', workflow_execution.state
      assert_not_equal 'completed', workflow_execution.state

      assert_no_enqueued_emails
    end

    test 'complete completing workflow_execution with no files' do
      workflow_execution = @workflow_execution_no_files

      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_b', workflow_execution.run_id
      # no files should be added to the run
      assert_equal 0, workflow_execution.outputs.count

      assert_equal 'completed', workflow_execution.state
    end

    test 'sample outputs on samples_workflow_executions' do
      workflow_execution = @workflow_execution_with_samples

      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_c', workflow_execution.run_id

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      assert_equal @sample41.puid, workflow_execution.samples_workflow_executions[0].sample.puid
      assert_equal @sample42.puid, workflow_execution.samples_workflow_executions[1].sample.puid

      assert_equal 2, workflow_execution.samples_workflow_executions[0].outputs.count
      # file blobs can be in either order
      if workflow_execution.samples_workflow_executions[0].outputs[0].filename == @normal2_output_analysis1_file_blob.filename # rubocop:disable Layout/LineLength
        output1 = workflow_execution.samples_workflow_executions[0].outputs[0]
        output2 = workflow_execution.samples_workflow_executions[0].outputs[1]
      else
        output2 = workflow_execution.samples_workflow_executions[0].outputs[0]
        output1 = workflow_execution.samples_workflow_executions[0].outputs[1]
      end
      # original file blob should not be the same as the output file blob, but contain the same file
      assert_not_equal @normal2_output_analysis1_file_blob.id, output1.id
      assert_equal @normal2_output_analysis1_file_blob.filename, output1.filename
      assert_equal @normal2_output_analysis1_file_blob.checksum, output1.file.checksum
      assert_not_equal @normal2_output_analysis2_file_blob.id, output2.id
      assert_equal @normal2_output_analysis2_file_blob.filename, output2.filename
      assert_equal @normal2_output_analysis2_file_blob.checksum, output2.file.checksum

      assert_equal 1, workflow_execution.samples_workflow_executions[1].outputs.count
      output3 = workflow_execution.samples_workflow_executions[1].outputs[0]
      # original file blob should not be the same as the output file blob, but contain the same file
      assert_not_equal @normal2_output_analysis3_file_blob.id, output3.id
      assert_equal @normal2_output_analysis3_file_blob.filename, output3.filename
      assert_equal @normal2_output_analysis3_file_blob.checksum, output3.file.checksum

      assert_equal 'completed', workflow_execution.state
    end

    test 'sample metadata on samples_workflow_executions' do
      workflow_execution = @workflow_execution_with_samples

      # Test start
      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_c', workflow_execution.run_id

      metadata1 = { 'number' => 1,
                    'organism' => 'an organism' }
      metadata2 = { 'number' => 2,
                    'organism' => 'a different organism' }

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      assert_equal metadata1, workflow_execution.samples_workflow_executions[0].metadata
      assert_equal metadata2, workflow_execution.samples_workflow_executions[1].metadata

      assert_equal 'completed', workflow_execution.state
    end

    test 'metadata on samples_workflow_executions merged into underlying samples when update_samples' do
      workflow_execution = @workflow_execution_with_samples

      old_metadata1 = { 'metadatafield1' => 'value1',
                        'organism' => 'the organism' }
      old_metadata2 = { 'metadatafield2' => 'value2',
                        'organism' => 'some organism' }
      new_metadata1 = { 'number' => 1,
                        'metadatafield1' => 'value1',
                        'organism' => 'an organism' }
      new_metadata2 = { 'number' => 2,
                        'metadatafield2' => 'value2',
                        'organism' => 'a different organism' }
      # Test start
      assert 'completing', workflow_execution.state

      assert_equal 'my_run_id_c', workflow_execution.run_id

      assert_equal old_metadata1, @sample41.metadata
      assert_equal old_metadata2, @sample42.metadata

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      @sample41.reload
      assert_equal new_metadata1, @sample41.metadata
      # test provenance updated correctly
      assert_equal workflow_execution.id, @sample41.reload.metadata_provenance['number']['id']
      assert_equal 'analysis', @sample41.reload.metadata_provenance['number']['source']
      assert_equal workflow_execution.id, @sample41.reload.metadata_provenance['organism']['id']
      assert_equal 'analysis', @sample41.reload.metadata_provenance['organism']['source']
      assert_nil @sample41.reload.metadata_provenance['metadatafield1']

      @sample42.reload
      assert_equal new_metadata2, @sample42.metadata
      # test provenance updated correctly
      assert_equal workflow_execution.id, @sample42.reload.metadata_provenance['number']['id']
      assert_equal 'analysis', @sample42.reload.metadata_provenance['number']['source']
      assert_equal workflow_execution.id, @sample42.reload.metadata_provenance['organism']['id']
      assert_equal 'analysis', @sample42.reload.metadata_provenance['organism']['source']
      assert_nil @sample42.reload.metadata_provenance['metadatafield2']

      assert_equal 'completed', workflow_execution.state
    end

    test 'metadata on samples_workflow_executions are not merged into underlying samples when not update_samples' do
      workflow_execution = @workflow_execution_with_samples_without_update_samples

      old_metadata1 = { 'metadatafield1' => 'value1',
                        'organism' => 'the organism' }
      old_metadata2 = { 'metadatafield2' => 'value2',
                        'organism' => 'some organism' }
      new_metadata1 = { 'number' => 1,
                        'metadatafield1' => 'value1',
                        'organism' => 'an organism' }
      new_metadata2 = { 'number' => 2,
                        'metadatafield2' => 'value2',
                        'organism' => 'a different organism' }
      # Test start
      assert 'completing', workflow_execution.state

      assert_equal 'my_run_id_f', workflow_execution.run_id

      assert_equal old_metadata1, @sample41.metadata
      assert_equal old_metadata2, @sample42.metadata

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      @sample41.reload
      assert_not_equal new_metadata1, @sample41.metadata

      @sample42.reload
      assert_not_equal new_metadata2, @sample42.metadata

      assert_equal 'completed', workflow_execution.state
    end

    test 'outputs on samples_workflow_executions added to samples attachments when update_samples' do
      workflow_execution = @workflow_execution_with_samples

      assert 'completing', workflow_execution.state

      assert_equal 'my_run_id_c', workflow_execution.run_id

      assert @sample41.attachments.empty?
      assert @sample41.attachments.empty?

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 2, @sample41.attachments.count
      sample41_output_filenames = @sample41.attachments.map { |attachment| attachment.filename.to_s }
      assert sample41_output_filenames.include?('analysis1.txt')
      assert sample41_output_filenames.include?('analysis2.txt')

      assert_equal 1, @sample42.attachments.count
      assert_equal 'analysis3.txt', @sample42.attachments[0].filename.to_s

      assert_equal 'completed', workflow_execution.state
    end

    test 'outputs on samples_workflow_executions not added to samples attachments when not update_samples' do
      workflow_execution = @workflow_execution_with_samples_without_update_samples

      assert 'completing', workflow_execution.state

      assert_equal 'my_run_id_f', workflow_execution.run_id

      assert @sample41.attachments.empty?
      assert @sample41.attachments.empty?

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 0, @sample41.attachments.count

      assert_equal 0, @sample42.attachments.count

      assert_equal 'completed', workflow_execution.state
    end

    test 'complex metadata on samples_workflow_executions' do
      workflow_execution = @workflow_execution_with_complex_metadata

      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_e', workflow_execution.run_id

      metadata1 = {
        'amr.0.end' => 5678,
        'amr.0.gene' => 'x',
        'amr.0.start' => 1234,
        'amr.1.end' => 2,
        'amr.1.gene' => 'y',
        'amr.1.start' => 1,
        'organism' => 'an organism'
      }
      metadata2 = {
        'amr.0.end' => 6789,
        'amr.0.gene' => 'x',
        'amr.0.start' => 2345,
        'amr.1.end' => 3,
        'amr.1.gene' => 'y',
        'amr.1.start' => 2,
        'organism' => 'a different organism'
      }

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      # samples workflow executions can be in either order
      if workflow_execution.samples_workflow_executions[0].sample.puid == 'INXT_SAM_AAAAAAAABQ'
        swe1 = workflow_execution.samples_workflow_executions[0]
        swe2 = workflow_execution.samples_workflow_executions[1]
      else
        swe2 = workflow_execution.samples_workflow_executions[0]
        swe1 = workflow_execution.samples_workflow_executions[1]
      end

      assert_equal metadata1, swe1.metadata
      assert_equal metadata2, swe2.metadata

      assert_equal 'completed', workflow_execution.state
    end

    test 'sample outputs metadata on samples_workflow_executions missing entry' do
      workflow_execution = @workflow_execution_missing_entry

      # Test start
      assert 'completing', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_d', workflow_execution.run_id

      # samples_workflow_executions can be in either order
      if workflow_execution.samples_workflow_executions[0].sample.name == 'WorkflowExecutions test sample 1'
        swe1 = workflow_execution.samples_workflow_executions[0]
        swe2 = workflow_execution.samples_workflow_executions[1]
      else
        swe2 = workflow_execution.samples_workflow_executions[0]
        swe1 = workflow_execution.samples_workflow_executions[1]
      end

      assert_equal 0, swe1.outputs.count

      assert_equal 1, swe2.outputs.count
      output3 = swe2.outputs[0]
      # original file blob should not be the same as the output file blob, but contain the same file
      assert_not_equal @missing_entry_output_analysis3_file_blob.id, output3.id
      assert_equal @missing_entry_output_analysis3_file_blob.filename, output3.filename
      assert_equal @missing_entry_output_analysis3_file_blob.checksum, output3.file.checksum

      metadata1 = { 'number' => 1,
                    'organism' => 'an organism' }

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      assert_equal metadata1, swe1.metadata
      assert swe2.metadata.empty?

      assert_equal 'completed', workflow_execution.state
    end
  end
end
