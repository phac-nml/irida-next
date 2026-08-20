# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class AttachmentsTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project = projects(:project1)
        @namespace = groups(:group_one)
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
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
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
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          assert_text 'test_file_D.fastq'
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
