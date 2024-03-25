# frozen_string_literal: true

require 'active_storage_test_case'

module WorkflowExecutions
  class CompletionServiceTest < ActiveStorageTestCase
    def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # normal/
      # get a new secure token for each workflow execution
      @workflow_execution_completed = workflow_executions(:irida_next_example_completed_a)
      blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_completed.blob_run_directory = blob_run_directory_a

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
      @workflow_execution_no_files = workflow_executions(:irida_next_example_completed_b)
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
      @workflow_execution_with_samples = workflow_executions(:irida_next_example_completed_c)
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

      # missing_entry/
      # get a new secure token for each workflow execution
      @workflow_execution_missing_entry = workflow_executions(:irida_next_example_completed_d)
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

      # associated test samples
      @sample41 = samples(:sample41)
      @sample42 = samples(:sample42)
    end

    test 'finalize completed workflow_execution' do
      workflow_execution = @workflow_execution_completed

      assert 'completed', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_a', workflow_execution.run_id
      assert_equal 1, workflow_execution.outputs.count
      # original file blob should not be the same as the output file blob, but contain the same file
      output_summary_file = workflow_execution.outputs[0]
      assert_not_equal @normal_output_summary_file_blob.id, output_summary_file.id
      assert_equal @normal_output_summary_file_blob.filename, output_summary_file.filename
      assert_equal @normal_output_summary_file_blob.checksum, output_summary_file.file.checksum

      assert_equal 'finalized', workflow_execution.state
    end

    test 'finalize non complete workflow_execution' do
      workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'completed', workflow_execution.state

      assert_not WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_not_equal 'completed', workflow_execution.state
      assert_not_equal 'finalized', workflow_execution.state
    end

    test 'finalize completed workflow_execution with no files' do
      workflow_execution = @workflow_execution_no_files

      assert 'completed', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_b', workflow_execution.run_id
      # no files should be added to the run
      assert_equal 0, workflow_execution.outputs.count

      assert_equal 'finalized', workflow_execution.state
    end

    test 'sample outputs on samples_workflow_executions' do
      workflow_execution = @workflow_execution_with_samples

      assert 'completed', workflow_execution.state

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

      assert_equal 'finalized', workflow_execution.state
    end

    test 'sample metadata on samples_workflow_executions' do
      workflow_execution = @workflow_execution_with_samples

      # Test start
      assert 'completed', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_c', workflow_execution.run_id

      metadata1 = { 'number' => 1,
                    'organism' => 'an organism' }
      metadata2 = { 'number' => 2,
                    'organism' => 'a different organism' }

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      assert_equal metadata1, workflow_execution.samples_workflow_executions[0].metadata
      assert_equal metadata2, workflow_execution.samples_workflow_executions[1].metadata

      assert_equal 'finalized', workflow_execution.state
    end

    test 'sample outputs metadata on samples_workflow_executions missing entry' do
      workflow_execution = @workflow_execution_missing_entry

      # Test start
      assert 'completed', workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

      assert_equal 'my_run_id_d', workflow_execution.run_id

      assert_equal 0, workflow_execution.samples_workflow_executions[0].outputs.count

      assert_equal 1, workflow_execution.samples_workflow_executions[1].outputs.count
      output3 = workflow_execution.samples_workflow_executions[1].outputs[0]
      # original file blob should not be the same as the output file blob, but contain the same file
      assert_not_equal @missing_entry_output_analysis3_file_blob.id, output3.id
      assert_equal @missing_entry_output_analysis3_file_blob.filename, output3.filename
      assert_equal @missing_entry_output_analysis3_file_blob.checksum, output3.file.checksum

      metadata1 = { 'number' => 1,
                    'organism' => 'an organism' }

      assert_equal 2, workflow_execution.samples_workflow_executions.count
      assert_equal metadata1, workflow_execution.samples_workflow_executions[0].metadata
      assert workflow_execution.samples_workflow_executions[1].metadata.empty?

      assert_equal 'finalized', workflow_execution.state
    end
  end
end
