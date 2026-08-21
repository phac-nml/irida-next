# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorTest < ActionDispatch::IntegrationTest
    include ActionView::Helpers::NumberHelper

    test 'fastq_1 displays both forward and non-pe files' do
      sample = samples(:sampleB)
      sign_in users(:jane_doe)
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_1',
                           selected_id: attachments(:attachmentPEFWD3).id,
                           namespace_id: sample.project.namespace.id, required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success
      attachments = [attachments(:attachmentPEFWD3), attachments(:attachmentPEFWD2), attachments(:attachmentPEFWD1),
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
            end
            # no rev files
            assert_select 'td', text: 'test_file_rev_3.fastq', count: 0
            assert_select 'td', text: 'test_file_rev_2.fastq', count: 0
            assert_select 'td', text: 'test_file_rev_1.fastq', count: 0
            assert_select 'td', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.no_file'), count: 0
          end
        end
      end
    end

    test 'fastq_2 displays only rev attachments' do
      sample = samples(:sampleB)
      sign_in users(:jane_doe)
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_2',
                           selected_id: attachments(:attachmentPEREV3).id,
                           namespace_id: sample.project.namespace.id, required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success

      attachments = [attachments(:attachmentPEREV3), attachments(:attachmentPEREV2), attachments(:attachmentPEREV1)]
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
            end
          end
          # no fwd or non-pe files
          assert_select 'td', text: 'test_file_fwd_3.fastq', count: 0
          assert_select 'td', text: 'test_file_fwd_2.fastq', count: 0
          assert_select 'td', text: 'test_file_fwd_1.fastq', count: 0
          assert_select 'td', text: 'test_file_14.fastq.gz', count: 0
          assert_select 'td', text: 'test_file_2.fastq.gz', count: 0
          assert_select 'td', text: 'test_file_D.fastq', count: 0
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
  end
end
