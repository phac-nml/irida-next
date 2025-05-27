# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class AttachmentsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      login_as @user
      @project1 = projects(:project1)
      @namespace = groups(:group_one)
      @attachment1 = attachments(:project1Attachment1)
      @attachment2 = attachments(:project1Attachment2)
    end

    test 'visiting the index' do
      visit namespace_project_path(@namespace, @project1)
      click_on I18n.t('projects.sidebar.files')

      assert_selector 'h1', text: I18n.t('projects.attachments.index.title')
      assert_selector '#attachments-table table tbody tr', count: 2
      assert_selector 'tr:first-child th', text: @attachment1.puid
      assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
      assert_selector 'tr:first-child td:nth-child(3)', text: @attachment1.metadata['format']
      assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
      assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: @attachment2.metadata['format']
    end

    test 'user with proper access can upload file' do
      visit namespace_project_attachments_path(@namespace, @project1)
      assert_selector '#attachments-table table tbody tr', count: 2

      assert_selector 'a', text: I18n.t('projects.attachments.index.upload_files')
      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/data_export_1.zip')
        # check that button goes from being enabled to disabled when clicked
        assert_selector '#t-upload-button:not(:disabled)'
        click_on I18n.t('attachments.dialogs.new_attachment_component.upload')
        assert_selector '#t-upload-button:disabled'
      end

      assert_selector '#attachments-table table tbody tr', count: 3
      within('tbody') do
        assert_text 'data_export_1.zip'
      end
    end

    test 'user without proper access cannot view upload button' do
      login_as users(:ryan_doe)
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_no_selector 'a', text: I18n.t('projects.attachments.index.upload_files')
    end

    test 'user without proper access cannot view files link on sidebar' do
      login_as users(:ryan_doe)
      visit namespace_project_path(@namespace, @project1)

      assert_no_selector 'a', text: I18n.t('projects.sidebar.files')
    end

    test 'should not be able to attach a duplicate file to a project' do
      visit namespace_project_attachments_path(@namespace, @project1)
      assert_selector '#attachments-table table tbody tr', count: 2

      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('attachments.dialogs.new_attachment_component.upload')
      end

      assert_text I18n.t('projects.attachments.create.success', filename: 'test_file_2.fastq.gz')

      assert_selector '#attachments-table table tbody tr', count: 3
      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('attachments.dialogs.new_attachment_component.upload')
      end

      assert_text I18n.t('projects.attachments.create.failure', filename: 'test_file_2.fastq.gz',
                                                                errors: 'File checksum matches existing file')
      assert_selector '#attachments-table table tbody tr', count: 3
    end

    test 'can sort by column' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.other', from: 1, to: 2, count: 2))
      assert_selector 'table tbody tr', count: 2

      click_on I18n.t('attachments.table_component.id')
      assert_selector 'table thead th[aria-sort="ascending"]', text: I18n.t('attachments.table_component.id').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.id')
      assert_selector 'table thead th[aria-sort="descending"]', text: I18n.t('attachments.table_component.id').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.filename')
      assert_selector 'table thead th[aria-sort="ascending"]',
                      text: I18n.t('attachments.table_component.filename').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.filename')
      assert_selector 'table thead th[aria-sort="descending"]',
                      text: I18n.t('attachments.table_component.filename').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.format')
      assert_selector 'table thead th[aria-sort="ascending"]', text: I18n.t('attachments.table_component.format').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.format')
      assert_selector 'table thead th[aria-sort="descending"]',
                      text: I18n.t('attachments.table_component.format').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.type')
      assert_selector 'table thead th[aria-sort="ascending"]', text: I18n.t('attachments.table_component.type').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.type')
      assert_selector 'table thead th[aria-sort="descending"]', text: I18n.t('attachments.table_component.type').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.byte_size')
      assert_selector 'table thead th[aria-sort="ascending"]',
                      text: I18n.t('attachments.table_component.byte_size').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.byte_size')
      assert_selector 'table thead th[aria-sort="descending"]',
                      text: I18n.t('attachments.table_component.byte_size').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.created_at')
      assert_selector 'table thead th[aria-sort="ascending"]',
                      text: I18n.t('attachments.table_component.created_at').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on I18n.t('attachments.table_component.created_at')
      assert_selector 'table thead th[aria-sort="descending"]',
                      text: I18n.t('attachments.table_component.created_at').upcase
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end
    end

    test 'can filter by filename or puid' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      fill_in placeholder: I18n.t(:'projects.attachments.index.search.placeholder'),
              with: @attachment1.file.filename.to_s
      find('input.t-search-component').native.send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_text @attachment1.puid
        assert_text @attachment1.file.filename.to_s
        assert_no_text @attachment2.puid
        assert_no_text @attachment2.file.filename.to_s
      end

      fill_in placeholder: I18n.t(:'projects.attachments.index.search.placeholder'),
              with: @attachment2.puid
      find('input.t-search-component').native.send_keys(:return)

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
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      within('table tbody') do
        assert_text @attachment1.file.filename.to_s
        assert_text @attachment2.file.filename.to_s
        click_link I18n.t('attachments.table_component.delete'), match: :first
      end

      within('dialog') do
        click_on I18n.t('attachments.dialogs.delete_attachment_component.submit_button')
      end

      assert_text I18n.t('projects.attachments.destroy.success', filename: @attachment1.file.filename.to_s)

      within('table tbody') do
        assert_no_text @attachment1.file.filename.to_s
        assert_text @attachment2.file.filename.to_s
        click_link I18n.t('attachments.table_component.delete'), match: :first
      end

      within('dialog') do
        click_on I18n.t('attachments.dialogs.delete_attachment_component.submit_button')
      end

      assert_text I18n.t('projects.attachments.destroy.success', filename: @attachment2.file.filename.to_s)

      assert_text I18n.t('projects.attachments.table.empty.title')
      assert_text I18n.t('projects.attachments.table.empty.description')
    end

    test 'can upload and delete paired end files' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                            Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz')]
        click_on I18n.t('attachments.dialogs.new_attachment_component.upload')
      end
      assert_selector '#attachments-table table tbody tr', count: 3
      assert_text 'Displaying 1-3 of 3 items'

      within('table tbody') do
        assert_selector 'tr:first-child td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
        assert_selector 'tr:first-child td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'fastq'
        assert_selector 'tr:first-child td:nth-child(4)', text: 'illumina_pe'
        within('tr:first-child') do
          click_link I18n.t('attachments.table_component.delete'), match: :first
        end
      end

      within('dialog') do
        click_on I18n.t('attachments.dialogs.delete_attachment_component.submit_button')
      end

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      within('table tbody') do
        assert_no_text 'TestSample_S1_L001_R2_001.fastq.gz'
        assert_no_text 'TestSample_S1_L001_R1_001.fastq.gz'
      end

      assert_text I18n.t('projects.attachments.destroy.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_text I18n.t('projects.attachments.destroy.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')
    end

    test 'rendering paired end attachments separately when filtering' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                            Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz')]
        click_on I18n.t('attachments.dialogs.new_attachment_component.upload')
      end

      assert_selector '#attachments-table table tbody tr', count: 3
      assert_text 'Displaying 1-3 of 3 items'

      # Assert that the success messages are present
      assert_text I18n.t('projects.attachments.create.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_text I18n.t('projects.attachments.create.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')

      within('table tbody') do
        assert_selector 'tr:first-child td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
        assert_selector 'tr:first-child td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'fastq'
        assert_selector 'tr:first-child td:nth-child(4)', text: 'illumina_pe'
      end

      # Wait for the flash messages to disappear
      assert_no_text I18n.t('projects.attachments.create.success', filename: 'TestSample_S1_L001_R2_001.fastq.gz')
      assert_no_text I18n.t('projects.attachments.create.success', filename: 'TestSample_S1_L001_R1_001.fastq.gz')

      fill_in placeholder: I18n.t(:'projects.attachments.index.search.placeholder'),
              with: 'fastq.gz'
      find('input.t-search-component').native.send_keys(:return)

      assert_selector '#attachments-table table tbody tr', count: 2
      assert_text 'Displaying 1-2 of 2 items'

      within('table tbody') do
        assert_selector 'tr:first-child td:nth-child(2)', text: 'TestSample_S1_L001_R1_001.fastq.gz'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'fastq'
        assert_selector 'tr:first-child td:nth-child(4)', text: 'illumina_pe'
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'TestSample_S1_L001_R2_001.fastq.gz'
        assert_selector 'tr:nth-child(2) td:nth-child(3)', text: 'fastq'
        assert_selector 'tr:nth-child(2) td:nth-child(4)', text: 'illumina_pe'
      end
    end

    test 'empty search state' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      fill_in placeholder: I18n.t(:'projects.attachments.index.search.placeholder'),
              with: 'filter that results in no attachments'
      find('input.t-search-component').native.send_keys(:return)

      assert_no_selector 'table'

      within 'section[role="status"]' do
        assert_text I18n.t('components.viral.pagy.empty_state.title')
        assert_text I18n.t('components.viral.pagy.empty_state.description')
      end
    end
  end
end
