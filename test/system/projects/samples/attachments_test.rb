# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class AttachmentsTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::DateHelper

      setup do
        @user = users(:john_doe)
        login_as @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project = projects(:project1)
        @namespace = groups(:group_one)
      end

      test 'user with role >= Maintainer should be able to see empty state with upload message' do
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button')
        assert_no_selector 'button[disabled]', text: I18n.t('projects.samples.show.concatenate_button')
        assert_no_selector 'button[disabled]', text: I18n.t('projects.samples.show.delete_files_button')
      end

      test 'user with role < Maintainer should not be able to see upload, concatenate and delete files buttons' do
        user = users(:ryan_doe)
        login_as user
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_no_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button')
        assert_no_selector 'button', text: I18n.t('projects.samples.show.concatenate_button')
        assert_no_selector 'button', text: I18n.t('projects.samples.show.delete_files_button')
        assert_text I18n.t('projects.samples.attachments.table.empty_state.no_permission_description')
      end

      test 'user with role >= Maintainer should be able to attach a file to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button')
        within('#sample-attachments') do
          assert_text I18n.t('projects.samples.attachments.table.empty_state.title')
          assert_text I18n.t('projects.samples.attachments.table.empty_state.description')
          assert_no_text 'test_file_2.fastq.gz'
        end
        click_on I18n.t('projects.samples.show.upload_files'), match: :first

        within('dialog[open]') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/data_export_1.zip')
          # check that button goes from being enabled to disabled when clicked
          assert_selector 'button[type=submit]:not(:disabled)'
          click_on I18n.t('projects.samples.show.upload')
          assert_selector 'button[type=submit]:disabled'
        end

        assert_text I18n.t('projects.samples.attachments.create.success', filename: 'data_export_1.zip')
        within('#sample-attachments') do
          assert_no_text I18n.t('projects.samples.show.no_files')
          assert_no_text I18n.t('projects.samples.show.no_associated_files')
          assert_text 'data_export_1.zip'
        end
      end

      test 'user with role >= Maintainer should not be able to attach a duplicate file to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_selector 'button', text: I18n.t('projects.samples.show.new_attachment_button')
        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog[open]') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file_2.fastq.gz')

        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog[open]') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.failure', filename: 'test_file_2.fastq.gz',
                                                                          errors: 'File checksum matches existing file')
      end

      test 'should not be able to upload uncompressed fastq files to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_selector 'button', text: I18n.t('projects.samples.show.new_attachment_button')
        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog[open]') do
          attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz'),
                                              Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                              Rails.root.join('test/fixtures/files/test_file.fastq')]
          assert_text I18n.t('projects.samples.show.files_ignored')
          assert_text 'test_file.fastq'

          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R1_001.fastq.gz')
        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R2_001.fastq.gz')
        assert_no_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file.fastq')

        # View paired files
        within('#sample-attachments') do
          assert_text 'TestSample_S1_L001_R1_001.fastq.gz'
          assert_text 'TestSample_S1_L001_R2_001.fastq.gz'
        end
      end

      test 'should be able to delete multiple attachments' do
        freeze_time
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        attachments = [attachments(:attachmentPEFWD1), attachments(:attachmentPEREV1), attachments(:attachmentPEFWD2),
                       attachments(:attachmentPEREV2), attachments(:attachmentPEFWD3), attachments(:attachmentPEREV3),
                       attachments(:attachmentD)]
        visit namespace_project_sample_url(namespace, project, sample)
        within '#sample-attachments' do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.delete_files_button'), match: :first
        within('dialog[open]') do
          assert_text I18n.t('projects.samples.attachments.deletions.modal.description.plural')
                          .gsub! 'COUNT_PLACEHOLDER',
                                 '7'
          within 'table tbody' do
            attachments.each do |attachment|
              assert_selector 'td:first-child', text: attachment.puid
              assert_selector 'td:nth-child(2)', text: attachment.file.filename.to_s
              assert_selector 'td:nth-child(3)', text: attachment.metadata['format']
              assert_selector 'td:nth-child(4)', text: number_to_human_size(attachment.file.byte_size)
              assert_selector 'td:last-child', text: attachment.created_at.strftime('%B %-d, %Y')
            end
          end
          click_on I18n.t('common.actions.delete')
        end
        assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
        within '#sample-attachments' do
          assert_selector 'table #attachments-table-body tr', count: 2
          assert_no_text 'test_file_fwd_1.fastq'
          assert_no_text 'test_file_rev_1.fastq'
          assert_no_text 'test_file_fwd_2.fastq'
          assert_no_text 'test_file_rev_2.fastq'
          assert_no_text 'test_file_fwd_3.fastq'
          assert_no_text 'test_file_rev_3.fastq'
          assert_no_text 'test_file_D.fastq'
        end
      end

      test 'deleting a selected attachment by row action updates selection count' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleC)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        pe_fwd_attachment = attachments(:attachmentPEFWD4)
        non_pe_attachment = attachments(:attachmentG)

        visit namespace_project_sample_url(namespace, project, sample)

        # no attachments selected/checked
        within 'tbody' do
          assert_selector 'input[name="attachment_ids[]"]', count: 8
          assert_selector 'input[name="attachment_ids[]"]:checked', count: 0
        end
        within 'tfoot' do
          assert_text "#{I18n.t('components.attachments.table_component.counts.attachments')}: 8"
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end

        # select a pe and non-pe attachment
        within '#sample-attachments' do
          assert_selector 'table #attachments-table-body tr', count: 8
          check "checkbox_attachment_#{pe_fwd_attachment.id}"
          check "checkbox_attachment_#{non_pe_attachment.id}"
        end

        # verify selection counts
        within 'tbody' do
          assert_selector 'input[name="attachment_ids[]"]', count: 8
          assert_selector 'input[name="attachment_ids[]"]:checked', count: 2
        end
        within 'tfoot' do
          assert_text "#{I18n.t('components.attachments.table_component.counts.attachments')}: 8"
          assert_selector 'strong[data-selection-target="selected"]', text: '2'
        end

        # delete pe attachment
        within "#attachment_#{pe_fwd_attachment.id}" do
          click_button I18n.t('common.actions.delete')
        end

        within 'dialog' do
          click_button I18n.t('common.controls.confirm')
        end

        # verify updated count
        within 'tbody' do
          assert_selector 'input[name="attachment_ids[]"]', count: 7
          assert_selector 'input[name="attachment_ids[]"]:checked', count: 1
        end
        within 'tfoot' do
          assert_text "#{I18n.t('components.attachments.table_component.counts.attachments')}: 7"
          assert_selector 'strong[data-selection-target="selected"]', text: '1'
        end
      end
    end
  end
end
