# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    # TODO: refactor this file when feature flag deferred_samplesheet is retired
    setup do
      sign_in users(:john_doe)
      @expected_fastq_params = {
        'attachable_id' => samples(:sample43).id,
        'attachable_type' => 'Sample',
        'index' => 0,
        'selected_id' => nil,
        'property' => 'fastq_1',
        'required_properties' => %w[sample fastq_1],
        'pattern' => '^\S+\.f(ast)?q(\.gz)?$',
        'namespace_id' => projects(:project37).namespace.id
      }

      @expected_other_params = {
        'attachable_id' => samples(:sample1).id,
        'attachable_type' => 'Sample',
        'index' => 1,
        'selected_id' => attachments(:attachment2).id,
        'property' => 'input',
        'required_properties' => nil,
        'namespace_id' => projects(:project1).namespace.id
      }
    end
    test 'new file selection with fastq params with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'new file selection with fastq params without feature flag' do
      @expected_fastq_params['index'] = 0
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with fastq params with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      attachment = attachments(:attachmentPEFWD43)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'create file selection with fastq params without feature flag' do
      @expected_fastq_params['index'] = 0
      attachment = attachments(:attachmentPEFWD43)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'new file selection with other params with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'new file selection with other params without feature flag' do
      @expected_other_params['index'] = 1
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with other params with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      attachment = attachments(:attachment1)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_other_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'create file selection with other params without feature flag' do
      @expected_other_params['index'] = 1
      attachment = attachments(:attachment1)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_other_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'unauthorized new file selection with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      sign_in users(:ryan_doe)
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'unauthorized new file selection without feature flag' do
      @expected_fastq_params['index'] = 0
      sign_in users(:ryan_doe)
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'unauthorized create file selection with feature flag' do
      Flipper.enable(:deferred_samplesheet)
      sign_in users(:ryan_doe)
      attachment = attachments(:attachmentPEFWD43)
      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :unauthorized
    end

    test 'unauthorized create file selection without feature flag' do
      @expected_fastq_params['index'] = 0
      sign_in users(:ryan_doe)
      attachment = attachments(:attachmentPEFWD43)
      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :unauthorized
    end
  end
end
