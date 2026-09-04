# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class FileSelectorTest < ActionDispatch::IntegrationTest
    include ActionView::Helpers::NumberHelper

    test 'can select attachment on shared sample' do
      sign_in users(:subgroup_sample_actions_doe)

      group = groups(:subgroup_sample_actions)
      sample = samples(:sample71)
      sample.attachments.create!(
        file: Rails.root.join('test/fixtures/files/08-5578-small_S1_L001_R1_001.fastq')
      )
      sample.attachments.create!(
        file: Rails.root.join('test/fixtures/files/08-5923-small_S1_L001_R1_001.fastq')
      )
      first_attachment = sample.attachments.first
      last_attachment = sample.attachments.last
      get new_workflow_executions_file_selector_path(
        params: {
          file_selector: { attachable_id: sample.id, attachable_type: 'Sample',
                           pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
                           property: 'fastq_1',
                           selected_id: last_attachment.id,
                           namespace_id: group.id, required_properties: %w[fastq_1 sample] }
        }
      )

      assert_response :success

      attachments = [first_attachment, last_attachment]
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
              if attachment == last_attachment
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]"
              else
                assert_select "input[id='attachment_id_#{attachment.id}'][checked]", count: 0
              end
            end
          end
          # required property so no "No File" selection option available
          assert_select 'td', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.no_file'), count: 0
        end
      end
    end
  end
end
