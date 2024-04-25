# frozen_string_literal: true

require 'test_helper'
require 'csv'

module WorkflowExecutions
  class PreparationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example)
    end

    test 'prepare workflow_execution with valid params' do
      assert @workflow_execution.initial?

      assert_difference -> { ActiveStorage::Attachment.count } => 2 do
        WorkflowExecutions::PreparationService.new(@workflow_execution, @user, {}).execute
      end

      assert_equal 1, @workflow_execution.inputs.size
      assert_equal 1, @workflow_execution.samples_workflow_executions.first.inputs.size

      assert @workflow_execution.workflow_params.key? 'input'
      assert @workflow_execution.workflow_params.key? 'outdir'
      assert_match @workflow_execution.inputs.first.blob.key, @workflow_execution.workflow_params['input']
      assert @workflow_execution.workflow_params['outdir'].ends_with?('/')
      assert @workflow_execution.blob_run_directory

      samplesheet_headers = %w[sample fastq_1 fastq_2]
      sample1_row = [@workflow_execution.samples_workflow_executions.first.sample.puid,
                     ActiveStorage::Blob.service.path_for(
                       format('%<run_dir>s/input/Sample_%<sample_id>s/%<filename>s',
                              run_dir: @workflow_execution.blob_run_directory,
                              sample_id: @workflow_execution.samples_workflow_executions.first.sample.id,
                              filename: attachments(:attachment1).filename)
                     ),
                     '']
      # ensure samplesheet csv has the correct order
      samplesheet_csv = CSV.parse(@workflow_execution.inputs.first.blob.download)
      assert_equal samplesheet_headers, samplesheet_csv[0]
      assert_equal sample1_row, samplesheet_csv[1]

      assert_equal 'prepared', @workflow_execution.state
    end
  end
end
