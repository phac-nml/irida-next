# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class AttachmentsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @attachment1 = attachments(:group1Attachment1)
      @attachment2 = attachments(:group1Attachment2)
    end

    test 'visiting the index' do
      visit group_path(@namespace)
      click_on I18n.t('groups.sidebar.files')

      assert_selector 'h1', text: I18n.t('groups.attachments.index.title')
      assert_selector '#attachments-table table tbody tr', count: 2

      within('#attachments-table table tbody') do
        [@attachment1, @attachment2].each do |attachment|
          within('tr', text: attachment.puid) do
            assert_text attachment.file.filename.to_s
            assert_text attachment.metadata['format']
          end
        end
      end
    end

    test 'user with proper access can upload file' do
      visit group_attachments_path(@namespace)
      assert_selector '#attachments-table table tbody tr', count: 2

      assert_selector 'button', text: I18n.t('components.attachments.dialogs.new_attachment_component.upload_files')
      click_on I18n.t('components.attachments.dialogs.new_attachment_component.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/data_export_1.zip')
        # check that button goes from being enabled to disabled when clicked
        assert_selector '#t-upload-button:not(:disabled)'
        click_on I18n.t('common.actions.upload')
        assert_selector '#t-upload-button:disabled'
      end

      assert_selector '#attachments-table table tbody tr', count: 3
      within('tbody') do
        assert_text 'data_export_1.zip'
      end
    end

    test 'user without proper access cannot view upload button' do
      login_as users(:ryan_doe)
      visit group_attachments_path(@namespace)

      assert_no_selector 'a', text: I18n.t('groups.attachments.index.upload_files')
    end

    test 'user without proper access cannot view files link on sidebar' do
      login_as users(:ryan_doe)
      visit group_path(@namespace)

      assert_no_selector 'a', text: I18n.t('groups.sidebar.files')
    end

    test 'should not be able to attach a duplicate file to a group' do
      visit group_attachments_path(@namespace)
      assert_selector '#attachments-table table tbody tr', count: 2

      click_on I18n.t('groups.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('common.actions.upload')
      end

      assert_text I18n.t('groups.attachments.create.success', filename: 'test_file_2.fastq.gz')

      assert_selector '#attachments-table table tbody tr', count: 3
      click_on I18n.t('groups.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('common.actions.upload')
      end

      assert_text I18n.t('groups.attachments.create.failure', filename: 'test_file_2.fastq.gz',
                                                              errors: 'File checksum matches existing file')
      assert_selector '#attachments-table table tbody tr', count: 3
    end

    test 'can filter by filename or puid' do
      visit group_attachments_path(@namespace)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      fill_in placeholder: I18n.t(:'groups.attachments.index.search.placeholder'),
              with: @attachment1.file.filename.to_s
      find('input.t-search-component').send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_text @attachment1.puid
        assert_text @attachment1.file.filename.to_s
        assert_no_text @attachment2.puid
        assert_no_text @attachment2.file.filename.to_s
      end

      fill_in placeholder: I18n.t(:'groups.attachments.index.search.placeholder'),
              with: @attachment2.puid
      find('input.t-search-component').send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_text @attachment2.puid
        assert_text @attachment2.file.filename.to_s
        assert_no_text @attachment1.puid
        assert_no_text @attachment1.file.filename.to_s
      end
    end

    test 'can delete files with delete action link' do
      visit group_attachments_path(@namespace)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      within('table tbody') do
        assert_text @attachment1.file.filename.to_s
        assert_text @attachment2.file.filename.to_s
        click_button I18n.t('common.actions.delete'), match: :first
      end

      deleted_filename = first_table_row_cell_text

      within('dialog') do
        click_on I18n.t('components.attachments.dialogs.delete_attachment_component.submit_button')
      end

      within('table tbody') do
        assert_no_text deleted_filename
        click_button I18n.t('common.actions.delete'), match: :first
      end

      second_deleted_filename = first_table_row_cell_text

      within('dialog') do
        click_on I18n.t('components.attachments.dialogs.delete_attachment_component.submit_button')
      end

      assert_text I18n.t('groups.attachments.table.empty.title')
      assert_text I18n.t('groups.attachments.table.empty.description')
      assert_not_equal deleted_filename, second_deleted_filename
    end

    test 'can upload and delete paired end files' do
      visit group_attachments_path(@namespace)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      click_on I18n.t('groups.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                            Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz')]
        click_on I18n.t('common.actions.upload')
      end
      assert_selector '#attachments-table table tbody tr', count: 3
      assert_text 'Displaying 1-3 of 3 items'

      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(3)', text: 'fastq'
      assert_selector 'table tbody tr td:nth-child(4)', text: 'illumina_pe'
      within('table tbody tr:first-child') do
        click_button I18n.t('common.actions.delete'), match: :first
      end

      within('dialog') do
        click_on I18n.t('components.attachments.dialogs.delete_attachment_component.submit_button')
      end

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      within('table tbody') do
        assert_no_text 'TestSample_S1_L001_R2_001.fastq.gz'
        assert_no_text 'TestSample_S1_L001_R1_001.fastq.gz'
      end

      assert_text I18n.t('groups.attachments.destroy.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_text I18n.t('groups.attachments.destroy.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')
    end

    test 'rendering paired end attachments separately when filtering' do
      visit group_attachments_path(@namespace)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      click_on I18n.t('groups.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                            Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz')]
        click_on I18n.t('common.actions.upload')
      end

      assert_selector '#attachments-table table tbody tr', count: 3
      assert_text 'Displaying 1-3 of 3 items'

      # Assert that the success messages are present
      assert_text I18n.t('groups.attachments.create.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_text I18n.t('groups.attachments.create.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')

      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(3)', text: 'fastq'
      assert_selector 'table tbody tr td:nth-child(4)', text: 'illumina_pe'

      # Wait for the flash messages to disappear
      assert_no_text I18n.t('groups.attachments.create.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_no_text I18n.t('groups.attachments.create.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')

      fill_in placeholder: I18n.t(:'groups.attachments.index.search.placeholder'),
              with: 'fastq.gz'
      find('input.t-search-component').send_keys(:return)

      assert_selector '#attachments-table table tbody tr', count: 2
      assert_text 'Displaying 1-2 of 2 items'

      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(3)', text: 'fastq'
      assert_selector 'table tbody tr td:nth-child(4)', text: 'illumina_pe'
      assert_selector 'table tbody tr td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
      assert_selector 'table tbody tr td:nth-child(3)', text: 'fastq'
      assert_selector 'table tbody tr td:nth-child(4)', text: 'illumina_pe'
    end

    test 'empty search state' do
      visit group_attachments_path(@namespace)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      fill_in placeholder: I18n.t(:'groups.attachments.index.search.placeholder'),
              with: 'filter that results in no attachments'
      find('input.t-search-component').send_keys(:return)

      assert_no_selector 'table'

      within 'section[role="status"]' do
        assert_text I18n.t('components.viral.pagy.empty_state.title')
        assert_text I18n.t('components.viral.pagy.empty_state.description')
      end
    end
  end
end
