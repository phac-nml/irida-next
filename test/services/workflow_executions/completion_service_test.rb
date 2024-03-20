# frozen_string_literal: true

require 'active_storage_test_case'

module WorkflowExecutions
  class CompletionServiceTest < ActiveStorageTestCase
    def setup
      @user = users(:john_doe)
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

      conn = Faraday.new
      assert WorkflowExecutions::CompletionService.new(@workflow_execution, conn, @user, {}).execute

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

      conn = Faraday.new

      assert_not WorkflowExecutions::CompletionService.new(@workflow_execution, conn, @user, {}).execute

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

      conn = Faraday.new
      assert WorkflowExecutions::CompletionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'my_run_id_6', @workflow_execution.run_id
      # no files should be added to the run
      assert_equal 0, @workflow_execution.outputs.count

      assert_equal 'finalized', @workflow_execution.state
    end
  end
end
