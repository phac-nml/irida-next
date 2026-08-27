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
        selected_id: nil,
        property: 'fastq_1',
        required_properties: %w[sample fastq_1],
        pattern: '^\S+\.f(ast)?q(\.gz)?$',
        namespace_id: projects(:project37).namespace.id
      }

      @expected_other_params = {
        attachable_id: samples(:sample1).id,
        attachable_type: 'Sample',
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
    test 'fastq_1 displays both forward and non-pe files' do
      sample = samples(:sampleB)
      selected_attachment = attachments(:attachmentPEFWD3)
      sign_in users(:jane_doe)
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_1',
                           selected_id: selected_attachment.id,
                           namespace_id: sample.project.namespace.id, required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success
      attachments = [selected_attachment, attachments(:attachmentPEFWD2), attachments(:attachmentPEFWD1),
                     attachments(:attachmentF), attachments(:attachmentE), attachments(:attachmentD)]
      assert_select 'table' do
        assert_select 'tbody' do
          attachments.each do |attachment|
            assert_select 'tr' do
              assert_select 'td', text: attachment.file.filename.to_s
              assert_select 'td', text: attachment.metadata['format']
              assert_select 'td', text: attachment.metadata['type']
              assert_select 'td', number_to_human_size(attachment.file.byte_size)
              assert_select 'td' do
                assert_select 'time[datetime=?]', attachment.created_at.iso8601
              end
              if attachment == selected_attachment
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]"
              else
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]", count: 0
              end
            end
          end
          # no rev files
          assert_select 'td', text: 'test_file_rev_3.fastq', count: 0
          assert_select 'td', text: 'test_file_rev_2.fastq', count: 0
          assert_select 'td', text: 'test_file_rev_1.fastq', count: 0
          assert_select 'td', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.no_file'), count: 0
        end
      end
    end

    test 'fastq_2 displays only rev attachments' do
      sample = samples(:sampleB)
      selected_attachment = attachments(:attachmentPEREV3)
      sign_in users(:jane_doe)
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_2',
                           selected_id: selected_attachment.id,
                           namespace_id: sample.project.namespace.id, required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success

      attachments = [selected_attachment, attachments(:attachmentPEREV2), attachments(:attachmentPEREV1)]
      assert_select 'table' do
        assert_select 'tbody' do
          attachments.each do |attachment|
            assert_select 'tr' do
              assert_select 'td', text: attachment.file.filename.to_s
              assert_select 'td', text: attachment.metadata['format']
              assert_select 'td', text: attachment.metadata['type']
              assert_select 'td', number_to_human_size(attachment.file.byte_size)
              assert_select 'td' do
                assert_select 'time[datetime=?]', attachment.created_at.iso8601
              end
              if attachment == selected_attachment
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]"
              else
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]", count: 0
              end
            end
          end
          # no fwd or non-pe files
          assert_select 'td', text: 'test_file_fwd_3.fastq', count: 0
          assert_select 'td', text: 'test_file_fwd_2.fastq', count: 0
          assert_select 'td', text: 'test_file_fwd_1.fastq', count: 0
          assert_select 'td', text: 'test_file_14.fastq.gz', count: 0
          assert_select 'td', text: 'test_file_2.fastq.gz', count: 0
          assert_select 'td', text: 'test_file_D.fastq', count: 0
          # not a required property so No File option available
          assert_select 'td', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.no_file')
        end
      end
    end

    test 'empty file selector state' do
      sample = samples(:sample3)
      sign_in users(:john_doe)
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_2', selected_id: '',
                           namespace_id: sample.project.namespace.id,
                           required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success

      assert_select 'table', count: 0
      assert_select 'h2', I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.title')
      assert_select 'span', I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.description')
    end

    test 'create file selection with fastq_1 params' do
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

    test 'create file selection with fastq_2 params' do
      attachment = attachments(:attachmentPEREV43)

      post workflow_executions_file_selector_index_path(
        file_selector:
        {
          attachable_id: samples(:sample43).id,
          attachable_type: 'Sample',
          selected_id: attachments(:attachmentPEREV43).id,
          property: 'fastq_2',
          required_properties: %w[sample fastq_1],
          pattern: '^\S+\.f(ast)?q(\.gz)?$',
          namespace_id: projects(:project37).namespace.id
        },
        attachment_id: attachment.id,
        format: :turbo_stream
      )

      assert_response :ok

      payload = parsed_files_payload

      assert_equal samples(:sample43).id, payload['attachable_id']
      assert_equal 2, payload['files'].length
      assert_equal 'fastq_2', payload['files'][0]['property']
      assert_equal attachment.id, payload['files'][0]['id']
      assert_equal 'fastq_1', payload['files'][1]['property']
      assert_equal attachments(:attachmentPEFWD43).id, payload['files'][1]['id']
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
