# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CompletionServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_completed)
    end

    def generate_input_key(run_dir, filename, prefix = '')
      format('%<run_dir>s/%<prefix>s%<filename>s', run_dir:, filename:, prefix:)
    end

    def compose_blob_with_custom_key(blob, key)
      ActiveStorage::Blob.new(
        key:,
        filename: blob.filename,
        byte_size: blob.byte_size,
        checksum: blob.checksum,
        content_type: blob.content_type
      ).tap do |copied_blob|
        copied_blob.compose([blob.key])
        copied_blob.save!
      end
    end

    def make_and_upload_blob(filepath:, blob_run_directory:)
      output_json_file = File.new(filepath, 'r')
      output_json_file_blob = ActiveStorage::Blob.create_and_upload!(
        io: output_json_file,
        filename: File.basename(filepath)
      )
      output_json_file_input_key = generate_input_key(blob_run_directory, output_json_file_blob.filename, 'output/')

      compose_blob_with_custom_key(output_json_file_blob, output_json_file_input_key)
    end

    test 'finalize completed workflow_execution' do
      # Test prep
      output_json_file_path = 'test/fixtures/files/blob_outputs/iridanext.output.json.gz'
      output_summary_file_path = 'test/fixtures/files/blob_outputs/summary.txt'
      blob_run_directory = ActiveStorage::Blob.generate_unique_secure_token

      output_json_file_blob = make_and_upload_blob(filepath: output_json_file_path, blob_run_directory:)
      output_summary_file_blob = make_and_upload_blob(filepath: output_summary_file_path, blob_run_directory:)

      @workflow_execution.blob_run_directory = blob_run_directory

      # Test start
      assert 'completed', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      # stubs.post('/runs') do
      #   [
      #     200,
      #     { 'Content-Type': 'application/json' },
      #     { run_id: 'abc123' }
      #   ]
      # end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::CompletionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'abc123', @workflow_execution.run_id

      assert_equal 'finalized', @workflow_execution.state
    end

    # test 'submit unprepared workflow_execution' do
    #   @workflow_execution = workflow_executions(:irida_next_example)

    #   stubs = Faraday::Adapter::Test::Stubs.new
    #   stubs.post('/runs') do
    #     [
    #       200,
    #       { 'Content-Type': 'application/json' },
    #       { run_id: 'abc123' }
    #     ]
    #   end

    #   conn = Faraday.new do |builder|
    #     builder.adapter :test, stubs
    #   end

    #   assert_not WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

    #   assert_nil @workflow_execution.run_id

    #   assert_not_equal 'submitted', @workflow_execution.state
    # end
  end
end
