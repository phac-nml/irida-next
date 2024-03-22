# frozen_string_literal: true

require 'active_storage_test_case'

module WorkflowExecutions
  class CompletionServiceTest < ActiveStorageTestCase
    def setup
      @workflow_execution = workflow_executions(:irida_next_example_completed)
    end

    test 'finalize completed workflow_execution' do
      # Test prep
      output_json_file_path = 'test/fixtures/files/blob_outputs/normal/iridanext.output.json.gz'
      output_summary_file_path = 'test/fixtures/files/blob_outputs/normal/summary.txt'
      blob_run_directory = ActiveStorage::Blob.generate_unique_secure_token

      make_and_upload_blob(filepath: output_json_file_path, blob_run_directory:)
      output_summary_file_blob = make_and_upload_blob(filepath: output_summary_file_path, blob_run_directory:)

      @workflow_execution.blob_run_directory = blob_run_directory

      # Test start
      assert 'completed', @workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(@workflow_execution, {}).execute

      assert_equal 'my_run_id_6', @workflow_execution.run_id
      assert_equal 1, @workflow_execution.outputs.count
      # original file blob should not be the same as the output file blob, but contain the same file
      output_summary_file = @workflow_execution.outputs[0]
      assert_not_equal output_summary_file_blob.id, output_summary_file.id
      assert_equal output_summary_file_blob.filename, output_summary_file.filename
      assert_equal output_summary_file_blob.checksum, output_summary_file.file.checksum

      assert_equal 'finalized', @workflow_execution.state
    end

    test 'finalize non complete workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'completed', @workflow_execution.state

      assert_not WorkflowExecutions::CompletionService.new(@workflow_execution, {}).execute

      assert_not_equal 'completed', @workflow_execution.state
      assert_not_equal 'finalized', @workflow_execution.state
    end

    test 'finalize completed workflow_execution with no files' do
      # Test prep
      output_json_file_path = 'test/fixtures/files/blob_outputs/no_files/iridanext.output.json.gz'
      blob_run_directory = ActiveStorage::Blob.generate_unique_secure_token

      make_and_upload_blob(filepath: output_json_file_path, blob_run_directory:)

      @workflow_execution.blob_run_directory = blob_run_directory

      # Test start
      assert 'completed', @workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(@workflow_execution, {}).execute

      assert_equal 'my_run_id_6', @workflow_execution.run_id
      # no files should be added to the run
      assert_equal 0, @workflow_execution.outputs.count

      assert_equal 'finalized', @workflow_execution.state
    end

    test 'sample outputs on samples_workflow_executions' do
      # Test prep
      @workflow_execution = workflow_executions(:irida_next_example_completed_with_samples)
      # override puid's so we can use the ones in the prepared iridanext.output.json.gz
      @sample1 = samples(:sample1)
      @sample1.puid = 'sample1puid'
      @sample1.save!
      @sample2 = samples(:sample2)
      @sample2.puid = 'sample2puid'
      @sample2.save!
      output_json_file_path = 'test/fixtures/files/blob_outputs/normal2/iridanext.output.json.gz'
      output_summary_file_path = 'test/fixtures/files/blob_outputs/normal2/summary.txt'
      output_analysis1_file_path = 'test/fixtures/files/blob_outputs/normal2/analysis1.txt'
      output_analysis2_file_path = 'test/fixtures/files/blob_outputs/normal2/analysis2.txt'
      output_analysis3_file_path = 'test/fixtures/files/blob_outputs/normal2/analysis3.txt'

      blob_run_directory = ActiveStorage::Blob.generate_unique_secure_token

      make_and_upload_blob(filepath: output_json_file_path, blob_run_directory:)
      make_and_upload_blob(filepath: output_summary_file_path, blob_run_directory:)
      output_analysis1_file_blob = make_and_upload_blob(filepath: output_analysis1_file_path, blob_run_directory:)
      output_analysis2_file_blob = make_and_upload_blob(filepath: output_analysis2_file_path, blob_run_directory:)
      output_analysis3_file_blob = make_and_upload_blob(filepath: output_analysis3_file_path, blob_run_directory:)

      @workflow_execution.blob_run_directory = blob_run_directory

      # Test start
      assert 'completed', @workflow_execution.state

      assert WorkflowExecutions::CompletionService.new(@workflow_execution, {}).execute

      assert_equal 'my_run_id_with_samples', @workflow_execution.run_id

      assert_equal 2, @workflow_execution.samples_workflow_executions.count
      assert_equal 'sample1puid', @workflow_execution.samples_workflow_executions[0].sample.puid
      assert_equal 'sample2puid', @workflow_execution.samples_workflow_executions[1].sample.puid

      assert_equal 2, @workflow_execution.samples_workflow_executions[0].outputs.count
      # original file blob should not be the same as the output file blob, but contain the same file
      output1 = @workflow_execution.samples_workflow_executions[0].outputs[0]
      assert_not_equal output_analysis1_file_blob.id, output1.id
      assert_equal output_analysis1_file_blob.filename, output1.filename
      assert_equal output_analysis1_file_blob.checksum, output1.file.checksum
      output2 = @workflow_execution.samples_workflow_executions[0].outputs[1]
      assert_not_equal output_analysis2_file_blob.id, output2.id
      assert_equal output_analysis2_file_blob.filename, output2.filename
      assert_equal output_analysis2_file_blob.checksum, output2.file.checksum

      assert_equal 1, @workflow_execution.samples_workflow_executions[1].outputs.count
      output3 = @workflow_execution.samples_workflow_executions[1].outputs[0]
      # original file blob should not be the same as the output file blob, but contain the same file
      assert_not_equal output_analysis3_file_blob.id, output3.id
      assert_equal output_analysis3_file_blob.filename, output3.filename
      assert_equal output_analysis3_file_blob.checksum, output3.file.checksum

      assert_equal 'finalized', @workflow_execution.state
    end
  end
end
