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
      visit namespace_project_attachments_path(@namespace, @project1)
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
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('projects.attachments.form.upload')
      end

      assert_selector '#attachments-table table tbody tr', count: 3
      within('tbody') do
        assert_text 'test_file_2.fastq.gz'
      end
    end

    test 'user without proper access cannot view upload button' do
      login_as users(:ryan_doe)
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_no_selector 'a', text: I18n.t('projects.attachments.index.upload_files')
    end

    test 'should not be able to attach a duplicate file to a project' do
      visit namespace_project_attachments_path(@namespace, @project1)
      assert_selector '#attachments-table table tbody tr', count: 2

      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('projects.attachments.form.upload')
      end
      assert_selector '#attachments-table table tbody tr', count: 3
      click_on I18n.t('projects.attachments.index.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
        click_on I18n.t('projects.attachments.form.upload')
      end

      assert_text 'checksum matches existing file'
      assert_selector '#attachments-table table tbody tr', count: 3
    end

    test 'can sort by column' do
      visit namespace_project_attachments_path(@namespace, @project1)

      assert_text 'Displaying 1-2 of 2 items'
      assert_selector 'table tbody tr', count: 2

      click_on 'ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on 'Filename'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on 'Filename'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'format'
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on 'format'
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'type'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'type'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'Size'
      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment2.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment2.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment1.file.filename.to_s
      end

      click_on 'Size'
      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'Uploaded'
      assert_selector 'table thead th:nth-child(6) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @attachment1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @attachment1.file.filename.to_s
        assert_selector 'tr:nth-child(2) th', text: @attachment2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @attachment2.file.filename.to_s
      end

      click_on 'Uploaded'
      assert_selector 'table thead th:nth-child(6) svg.icon-arrow_down'
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

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_text @attachment2.puid
        assert_text @attachment2.file.filename.to_s
        assert_no_text @attachment1.puid
        assert_no_text @attachment1.file.filename.to_s
      end
    end
  end
end
