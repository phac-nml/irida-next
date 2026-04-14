# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    # TODO: refactor this file when feature flag v2_samplesheet is retired
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
      Flipper.enable(:v2_samplesheet)
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'new file selection with fastq params without feature flag' do
      @expected_fastq_params['index'] = 0
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with fastq params with feature flag' do
      Flipper.enable(:v2_samplesheet)
      attachment = attachments(:attachmentPEFWD43)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok

      payload = parsed_v2_files_payload

      assert_equal samples(:sample43).id, payload['attachable_id']
      assert_equal 2, payload['files'].length
      assert_equal 'fastq_1', payload['files'][0]['property']
      assert_equal attachment.id, payload['files'][0]['id']
      assert_equal 'fastq_2', payload['files'][1]['property']
      assert_equal attachments(:attachmentPEREV43).id, payload['files'][1]['id']
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

      payload = parsed_v1_files_payload

      assert_equal '0', payload['index']
      assert_equal 2, payload['files'].length
      assert_equal 'fastq_1', payload['files'][0]['property']
      assert_equal attachment.id, payload['files'][0]['id']
      assert_equal 'fastq_2', payload['files'][1]['property']
      assert_equal attachments(:attachmentPEREV43).id, payload['files'][1]['id']
    end

    test 'create file selection with no attachment keeps empty payload for selected property' do
      Flipper.enable(:v2_samplesheet)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: 'no_attachment',
        format: :turbo_stream
      )

      assert_response :ok

      payload = parsed_v2_files_payload

      assert_equal 1, payload['files'].length
      assert_equal 'fastq_1', payload['files'][0]['property']
      assert_equal '', payload['files'][0]['id']
      assert_equal '', payload['files'][0]['filename']
    end

    test 'new file selection with other params with feature flag' do
      Flipper.enable(:v2_samplesheet)
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'new file selection with other params without feature flag' do
      @expected_other_params['index'] = 1
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with other params with feature flag' do
      Flipper.enable(:v2_samplesheet)
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
      Flipper.enable(:v2_samplesheet)
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
      Flipper.enable(:v2_samplesheet)
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

    private

    def parsed_v2_files_payload
      doc = Nokogiri::HTML(response.body)

      JSON.parse(doc.at_css('[data-payload-type="files"]')['data-files'])
    end

    def parsed_v1_files_payload
      doc = Nokogiri::HTML(response.body)

      JSON.parse(doc.at_css('[data-controller="nextflow--v1--file"]')['data-nextflow--v1--file-files-value'])
    end
  end
end
