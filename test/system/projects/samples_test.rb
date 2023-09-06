# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'visiting the index' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_text @sample1.name
      assert_text @sample2.name

      assert_selector 'button.Viral-Dropdown--icon', count: 5
    end

    test 'cannot access project samples' do
      login_as users(:david_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
    end

    test 'should create sample' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      click_on I18n.t('projects.samples.index.new_button')

      fill_in I18n.t('activerecord.attributes.sample.description'), with: @sample1.description
      fill_in I18n.t('activerecord.attributes.sample.name'), with: 'New Name'
      click_on I18n.t('projects.samples.new.submit_button')

      assert_text I18n.t('projects.samples.create.success')
      assert_text 'New Name'
      assert_text @sample1.description
    end

    test 'should update Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 1
      click_on I18n.t('projects.samples.show.edit_button'), match: :first

      fill_in 'Description', with: @sample1.description
      fill_in 'Name', with: 'New Sample Name'
      click_on I18n.t('projects.samples.edit.submit_button')

      assert_text I18n.t('projects.samples.update.success')
      assert_text 'New Sample Name'
      assert_text @sample1.description
    end

    test 'user with role >= Maintainer should be able to attach a file to a Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample2.id)
      assert_selector 'button', text: I18n.t('projects.samples.show.upload_file'), count: 1
      click_on I18n.t('projects.samples.show.upload_file')

      within('dialog') do
        attach_file 'attachment[file]', Rails.root.join('test/fixtures/files/test_file.fastq')
        click_on I18n.t('projects.samples.show.upload_file')
      end

      assert_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file.fastq')
      within('#attachments') do
        assert_text 'test_file.fastq'
      end
    end

    test 'user with role >= Maintainer should not be able to attach a duplicate file to a Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'button', text: I18n.t('projects.samples.show.upload_file'), count: 1
      click_on I18n.t('projects.samples.show.upload_file')

      within('dialog') do
        attach_file 'attachment[file]', Rails.root.join('test/fixtures/files/test_file.fastq')
        click_on I18n.t('projects.samples.show.upload_file')
      end

      within('dialog') do
        assert_text 'checksum matches existing file'
      end
    end

    test 'user with role >= Maintainer should be able to delete a file from a Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'button', text: I18n.t('projects.samples.attachments.attachment.delete'), count: 1
      click_on I18n.t('projects.samples.attachments.attachment.delete')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'test_file.fastq')
      within('#attachments') do
        assert_no_text 'test_file.fastq'
      end
    end

    test 'should destroy Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 1
      click_link I18n.t(:'projects.samples.index.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.destroy.success', sample_name: @sample1.name)
    end

    test 'user should not be able to see the edit button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)

      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 0
    end

    test 'user should not be able to see the remove button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)

      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 0
    end

    test 'user should not be able to see the upload file button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)

      assert_selector 'a', text: I18n.t('projects.samples.index.upload_file'), count: 0
    end

    test 'visiting the index should not allow the current user only edit action' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 2
      first('table#samples-table tr button.Viral-Dropdown--icon').click
      assert_selector 'a', text: 'Edit', count: 1
      assert_selector 'a', text: 'Remove', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'visiting the index should not allow the current user any modification actions' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 0
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end
  end
end
