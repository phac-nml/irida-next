# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)
      @expected_fastq_params = {
        'attachable_id' => samples(:sample43).id,
        'attachable_type' => 'Sample',
        'index' => 0,
        'selected_id' => nil,
        'property' => 'fastq_1',
        'required_properties' => %w[sample fastq_1],
        'pattern' => '^\S+\.f(ast)?q(\.gz)?$'
      }

      @expected_other_params = {
        'attachable_id' => samples(:sample1).id,
        'attachable_type' => 'Sample',
        'index' => 1,
        'selected_id' => attachments(:attachment2).id,
        'property' => 'input',
        'required_properties' => nil
      }
    end
    test 'new file selection with fastq params' do
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with fastq params' do
      attachment = attachments(:attachmentPEFWD43)
      sign_in users(:jeff_doe)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'new file selection with other params' do
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with other params' do
      attachment = attachments(:attachment1)
      sign_in users(:jeff_doe)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_other_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end
  end
end
