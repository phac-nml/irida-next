# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)

      @expected_fastq_params = {
        attachable_id: samples(:sample43).id,
        attachable_type: 'Sample',
        index: 0,
        selected_id: nil,
        property: 'fastq_1',
        required_properties: %w[sample fastq_1],
        pattern: '^\S+\.f(ast)?q(\.gz)?$',
        namespace_id: projects(:project37).namespace.id
      }

      @expected_other_params = {
        attachable_id: samples(:sample1).id,
        attachable_type: 'Sample',
        index: 1,
        selected_id: attachments(:attachment2).id,
        property: 'input',
        required_properties: nil,
        namespace_id: projects(:project1).namespace.id
      }

      @project_ref_params = {
        attachable_id: projects(:snvphyl_project).namespace.id,
        attachable_type: Namespaces::ProjectNamespace.sti_name,
        selected_id: '',
        property: 'refgenome',
        pattern: '^\\S+\\.f(ast)?a(\\.gz)?$',
        namespace_id: projects(:snvphyl_project).namespace.id
      }

      @group_ref_params = {
        attachable_id: groups(:snvphyl_group).id,
        attachable_type: Group.sti_name,
        selected_id: '',
        property: 'refgenome',
        pattern: '^\\S+\\.f(ast)?a(\\.gz)?$',
        namespace_id: groups(:snvphyl_group).id
      }
    end

    test 'create file selection with fastq params' do
      attachment = attachments(:attachmentPEFWD43)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok

      payload = parsed_files_payload

      assert_equal samples(:sample43).id, payload['attachable_id']
      assert_equal 2, payload['files'].length
      assert_equal 'fastq_1', payload['files'][0]['property']
      assert_equal attachment.id, payload['files'][0]['id']
      assert_equal 'fastq_2', payload['files'][1]['property']
      assert_equal attachments(:attachmentPEREV43).id, payload['files'][1]['id']
    end

    test 'create project file selection with fastq params' do
      sign_in users(:snvphyl_user)
      attachment = attachments(:snvphyl_project_attachment_ref)

      post workflow_executions_file_selector_index_path(
        file_selector: @project_ref_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok

      property = @project_ref_params[:property]
      link_target_id = "workflow_execution_workflow_params_#{property}_link"
      input_target_id = "workflow_execution_workflow_params_#{property}"
      doc = Nokogiri::HTML(response.parsed_body)
      link = doc.at_css("turbo-stream[target=\"#{link_target_id}\"] template a")
      input = doc.at_css("turbo-stream[target=\"#{input_target_id}\"] template input")

      assert_equal attachment.filename.to_s, link.text
      assert_equal 'autofocus', link['autofocus']
      assert_equal attachment.to_global_id.to_s, input['value']
    end

    test 'create group file selection with fastq params' do
      sign_in users(:snvphyl_user)
      attachment = attachments(:snvphyl_group_attachment_ref)

      post workflow_executions_file_selector_index_path(
        file_selector: @group_ref_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok

      property = @group_ref_params[:property]
      link_target_id = "workflow_execution_workflow_params_#{property}_link"
      input_target_id = "workflow_execution_workflow_params_#{property}"
      doc = Nokogiri::HTML(response.parsed_body)
      link = doc.at_css("turbo-stream[target=\"#{link_target_id}\"] template a")
      input = doc.at_css("turbo-stream[target=\"#{input_target_id}\"] template input")

      assert_equal attachment.filename.to_s, link.text
      assert_equal 'autofocus', link['autofocus']
      assert_equal attachment.to_global_id.to_s, input['value']
    end

    test 'create file selection with no attachment keeps empty payload for selected property' do
      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: 'no_attachment',
        format: :turbo_stream
      )

      assert_response :ok

      payload = parsed_files_payload

      assert_equal 1, payload['files'].length
      assert_equal 'fastq_1', payload['files'][0]['property']
      assert_equal '', payload['files'][0]['id']
      assert_equal '', payload['files'][0]['filename']
    end

    test 'new file selection with other params' do
      get new_workflow_executions_file_selector_path(file_selector: @expected_other_params, format: :turbo_stream)

      assert_response :ok
    end

    test 'create file selection with other params' do
      attachment = attachments(:attachment1)

      post workflow_executions_file_selector_index_path(
        file_selector: @expected_other_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok
    end

    test 'create file selection with attachment outside attachable responds not found' do
      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachments(:attachment1).id,
        format: :turbo_stream
      )

      assert_response :not_found
    end

    test 'unauthorized new file selection' do
      sign_in users(:ryan_doe)
      get new_workflow_executions_file_selector_path(file_selector: @expected_fastq_params, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'unauthorized create file selection' do
      sign_in users(:ryan_doe)
      attachment = attachments(:attachmentPEFWD43)
      post workflow_executions_file_selector_index_path(
        file_selector: @expected_fastq_params,
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :unauthorized
    end

    test 'new file selection with invalid attachable_id and attachable type Sample' do
      get new_workflow_executions_file_selector_path(
        file_selector: @expected_fastq_params.merge(attachable_id: 'invalid id'),
        format: :turbo_stream
      )

      assert_response :not_found
    end

    test 'new file selection with invalid attachable_id and attachable type Namespace' do
      sign_in users(:snvphyl_user)
      get new_workflow_executions_file_selector_path(
        file_selector: @project_ref_params.merge(attachable_id: 'invalid id'),
        format: :turbo_stream
      )

      assert_response :not_found
    end

    test 'new file selection with invalid attachable_type' do
      get new_workflow_executions_file_selector_path(
        file_selector: @expected_fastq_params.merge(attachable_type: 'invalid type'),
        format: :turbo_stream
      )

      assert_response :not_found
    end

    private

    def parsed_files_payload
      doc = Nokogiri::HTML(response.body) # rubocop:disable Rails/ResponseParsedBody

      JSON.parse(doc.at_css('[data-payload-type="files"]')['data-files'])
    end
  end
end
