# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample3 = samples(:sample30)
      @sample32 = samples(:sample32)
      @project = projects(:project1)
      @project2 = projects(:projectA)
      @project29 = projects(:project29)
      @namespace = groups(:group_one)
      @group12a = groups(:subgroup_twelve_a)
    end

    test 'visiting the index' do
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tbody tr', count: 3
      assert_text @sample1.name
      assert_text @sample2.name

      assert_selector 'button.Viral-Dropdown--icon', count: 6
    end

    test 'cannot access project samples' do
      login_as users(:user_no_access)

      visit namespace_project_samples_url(@namespace, @project)

      assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
    end

    test 'should create sample' do
      visit namespace_project_samples_url(@namespace, @project)
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
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 1
      click_on I18n.t('projects.samples.show.edit_button'), match: :first

      fill_in 'Description', with: @sample1.description
      fill_in 'Name', with: 'New Sample Name'
      click_on I18n.t('projects.samples.edit.submit_button')

      assert_text I18n.t('projects.samples.update.success')
      assert_text 'New Sample Name'
      assert_text @sample1.description
    end

    test 'user with role >= Maintainer should be able to see upload, concatenate and delete files buttons' do
      visit namespace_project_sample_url(@namespace, @project, @sample2)
      assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
      assert_selector 'a', text: I18n.t('projects.samples.show.concatenate_button'), count: 1
      assert_selector 'a', text: I18n.t('projects.samples.show.delete_files_button'), count: 1
    end

    test 'user with role < Maintainer should not be able to see upload, concatenate and delete files buttons' do
      user = users(:ryan_doe)
      login_as user
      visit namespace_project_sample_url(@namespace, @project, @sample2)
      assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 0
      assert_selector 'a', text: I18n.t('projects.samples.show.concatenate_button'), count: 0
      assert_selector 'a', text: I18n.t('projects.samples.show.delete_files_button'), count: 0
    end

    test 'user with role >= Maintainer should be able to attach a file to a Sample' do
      visit namespace_project_sample_url(@namespace, @project, @sample2)
      assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
      within('#table-listing') do
        assert_text I18n.t('projects.samples.show.no_files')
        assert_text I18n.t('projects.samples.show.no_associated_files')
        assert_no_text 'test_file.fastq'
      end
      click_on I18n.t('projects.samples.show.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file.fastq')
        click_on I18n.t('projects.samples.show.upload')
      end

      assert_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file.fastq')
      within('#table-listing') do
        assert_no_text I18n.t('projects.samples.show.no_files')
        assert_no_text I18n.t('projects.samples.show.no_associated_files')
        assert_text 'test_file.fastq'
      end
    end

    test 'user with role >= Maintainer should not be able to attach a duplicate file to a Sample' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
      click_on I18n.t('projects.samples.show.upload_files')

      within('dialog') do
        attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file.fastq')
        click_on I18n.t('projects.samples.show.upload')
      end

      assert_text 'checksum matches existing file'
    end

    test 'user with role >= Maintainer should be able to delete a file from a Sample' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_selector 'button', text: I18n.t('projects.samples.attachments.attachment.delete'), count: 2

      within('#attachments-table-body') do
        click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'test_file.fastq')
      within('#table-listing') do
        assert_no_text 'test_file.fastq'
      end
    end

    test 'user with role >= Maintainer should be able to attach, view, and destroy paired files to a Sample' do
      visit namespace_project_sample_url(@namespace, @project, @sample2)
      # Initial View
      assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
      within('#table-listing') do
        assert_text I18n.t('projects.samples.show.no_files')
        assert_text I18n.t('projects.samples.show.no_associated_files')
        assert_selector 'button', text: I18n.t('projects.samples.attachments.attachment.delete'), count: 0
      end
      click_on I18n.t('projects.samples.show.upload_files')

      # Attach paired files
      within('dialog') do
        attach_file 'attachment[files][]',
                    [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq'),
                     Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq')]
        click_on I18n.t('projects.samples.show.upload')
      end

      assert_text I18n.t('projects.samples.attachments.create.success', filename: 'TestSample_S1_L001_R1_001.fastq')
      assert_text I18n.t('projects.samples.attachments.create.success', filename: 'TestSample_S1_L001_R2_001.fastq')

      # View paired files
      within('#table-listing') do
        assert_text 'TestSample_S1_L001_R1_001.fastq'
        assert_text 'TestSample_S1_L001_R2_001.fastq'
        assert_selector 'button', text: I18n.t('projects.samples.attachments.attachment.delete'), count: 1
      end

      # Destroy paired files
      within('#attachments-table-body') do
        click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'TestSample_S1_L001_R1_001.fastq')
      assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'TestSample_S1_L001_R2_001.fastq')
      within('#table-listing') do
        assert_no_text 'TestSample_S1_L001_R1_001.fastq'
        assert_no_text 'TestSample_S1_L001_R2_001.fastq'
        assert_text I18n.t('projects.samples.show.no_files')
        assert_text I18n.t('projects.samples.show.no_associated_files')
      end
    end

    test 'should destroy Sample from sample show page' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 1
      click_link I18n.t(:'projects.samples.index.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.destroy.success', sample_name: @sample1.name,
                                                             project_name: @project.namespace.human_name)

      assert_no_selector 'table#samples-table tbody tr', text: @sample1.name
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      assert_selector 'table#samples-table tbody tr', count: 2
      within first('tbody tr td:first-child') do
        assert_text @sample2.name
      end
    end

    test 'should destroy Sample from sample listing page' do
      visit namespace_project_samples_url(@namespace, @project)

      table_row = find(:table_row, { 'Sample' => @sample1.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link 'Remove'
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.destroy.success', sample_name: @sample1.name,
                                                             project_name: @project.namespace.human_name)

      assert_no_selector 'table#samples-table tbody tr', text: @sample1.name
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      assert_selector 'table#samples-table tbody tr', count: 2
      within first('tbody tr td:first-child') do
        assert_text @sample2.name
      end
    end

    test 'should transfer samples' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      within 'table#samples-table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        select project2.full_path, from: I18n.t('projects.samples.transfers._transfer_modal.new_project_id')
        click_on I18n.t('projects.samples.transfers._transfer_modal.submit_button')
      end
      within %(turbo-frame[id="project_samples_list"]) do
        assert_selector 'table#samples-table tbody tr', count: 0
      end
    end

    test 'should not transfer samples' do
      project26 = projects(:project26)
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'table#samples-table tbody tr', count: 3
      all('input[type=checkbox]').last.click

      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        select project26.full_path, from: I18n.t('projects.samples.transfers._transfer_modal.new_project_id')
        click_on I18n.t('projects.samples.transfers._transfer_modal.submit_button')
      end
      within %(turbo-frame[id="transfer_alert"]) do
        assert_text I18n.t('projects.samples.transfers.create.error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
      end
      within %(turbo-frame[id="project_samples_list"]) do
        assert_selector 'table#samples-table tbody tr', count: 3
      end
    end

    test 'should transfer some samples' do
      project25 = projects(:project25)
      visit namespace_project_samples_url(@namespace, @project)
      within 'table#samples-table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end

      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        select project25.full_path, from: I18n.t('projects.samples.transfers._transfer_modal.new_project_id')
        click_on I18n.t('projects.samples.transfers._transfer_modal.submit_button')
      end
      within %(turbo-frame[id="transfer_alert"]) do
        assert_text I18n.t('projects.samples.transfers.create.error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
      end
      within %(turbo-frame[id="project_samples_list"]) do
        assert_selector 'table#samples-table tbody tr', count: 1
      end
    end

    test 'should transfer samples for maintainer within hierarchy' do
      user = users(:joan_doe)
      login_as user

      project2 = projects(:project2)
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      within 'table#samples-table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        select project2.full_path, from: I18n.t('projects.samples.transfers._transfer_modal.new_project_id')
        click_on I18n.t('projects.samples.transfers._transfer_modal.submit_button')
      end
      within %(turbo-frame[id="project_samples_list"]) do
        assert_selector 'table#samples-table tbody tr', count: 0
      end
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      user = users(:user28)
      login_as user
      namespace = groups(:group_hotel)
      project2 = projects(:projectHotel)
      visit namespace_project_samples_url(namespace, project2)
      within 'table#samples-table tbody' do
        assert_selector 'tr', count: 1
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_no_selector 'option'
      end
    end

    test 'should not transfer samples for maintainer outside of hierarchy' do
      user = users(:joan_doe)
      login_as user

      # Project is a part of Group 8 and not a part of the current project hierarchy
      project32 = projects(:project32)
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      within 'table#samples-table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first

      within('span[data-controller-connected="true"] dialog') do
        assert_no_selector "option[value='#{project32.full_path}']"
      end
    end

    test 'user with maintainer access should be able to see the transfer samples button' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.transfer_button'), count: 1
    end

    test 'user with guest access should not be able to see the transfer samples button' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.transfer_button'), count: 0
    end

    test 'user should not be able to see the edit button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(@namespace, @project, @sample1)

      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 0
    end

    test 'user should not be able to see the remove button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(@namespace, @project, @sample1)

      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 0
    end

    test 'user should not be able to see the upload file button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(@namespace, @project, @sample1)

      assert_selector 'a', text: I18n.t('projects.samples.index.upload_file'), count: 0
    end

    test 'visiting the index should not allow the current user only edit action' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tbody tr', count: 3
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 3
      first('table#samples-table tr button.Viral-Dropdown--icon').click
      assert_selector 'a', text: 'Edit', count: 1
      assert_selector 'a', text: 'Remove', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'visiting the index should not allow the current user any modification actions' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 0
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tbody tr', count: 3
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'can search the list of samples by name' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table#samples-table tbody tr', count: 3
      assert_text @sample1.name
      assert_text @sample2.name

      fill_in I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name

      assert_selector 'table#samples-table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name
    end

    test 'can sort samples by column' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody tr td:first-child') do
        assert_text @sample1.name
      end

      click_on I18n.t('projects.samples.table.sample')

      assert_selector 'table thead th:first-child svg.icon-arrow_up'
      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample1.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample3.name
      end

      click_on I18n.t('projects.samples.table.sample')

      assert_selector 'table thead th:first-child svg.icon-arrow_down'
      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample3.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample1.name
      end

      click_on I18n.t('projects.samples.table.created_at')

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample3.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample1.name
      end

      click_on I18n.t('projects.samples.table.created_at')

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample1.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample3.name
      end

      click_on I18n.t('projects.samples.table.updated_at')

      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_up'
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample3.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample1.name
      end

      click_on I18n.t('projects.samples.table.updated_at')

      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample1.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample3.name
      end
    end

    test 'can filter and then sort the list of samples' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody tr td:first-child') do
        assert_text @sample1.name
      end

      fill_in I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name

      assert_selector 'table#samples-table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name

      click_on I18n.t('projects.samples.table.sample')

      assert_selector 'table#samples-table tbody tr', count: 1
      within first('tbody tr td:first-child') do
        assert_text @sample1.name
      end
    end

    test 'can sort and then filter the list of samples' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody tr td:first-child') do
        assert_text @sample1.name
      end

      click_on I18n.t('projects.samples.table.sample')
      click_on I18n.t('projects.samples.table.sample')

      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody tr td:first-child') do
        assert_text @sample3.name
      end

      fill_in I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name

      assert_selector 'table#samples-table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name
    end

    test 'should concatenate single end attachment files and keep originals' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file.fastq'
        assert_text 'test_file_A.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_text 'concatenated_file'
        assert_selector 'table #attachments-table-body tr', count: 3
      end
    end

    test 'should concatenate paired end attachment files and keep originals' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_text 'concatenated_file'
        assert_selector 'table #attachments-table-body tr', count: 7
      end
    end

    test 'should concatenate single end attachment files and remove originals' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file.fastq'
        assert_text 'test_file_A.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        check 'Delete originals'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_text 'concatenated_file'
        assert_selector 'table #attachments-table-body tr', count: 1
      end
    end

    test 'should concatenate paired end attachment files and remove originals' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        check 'Delete originals'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_text 'concatenated_file_1.fastq'
        assert_text 'concatenated_file_2.fastq'
        assert_selector 'table #attachments-table-body tr', count: 4
      end
    end

    test 'should not concatenate single and paired end attachment files' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        assert_text 'test_file_D.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="concatenation-alert"]) do
        assert_text I18n.t('services.attachments.concatenation.incorrect_file_types')
      end
    end

    test 'should not concatenate compressed and uncompressed attachment files' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_2.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_D.fastq'
        assert_text 'test_file_2.fastq.gz'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="concatenation-alert"]) do
        assert_text I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
      end
    end

    test 'user with guest access should not be able to see the concatenate attachment files button' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(@namespace, @project, @sample1)

      assert_selector 'a', text: I18n.t('projects.samples.show.concatenate_button'), count: 0
    end

    test 'shouldn\'t concatenate files as the basename provided is not in the correct format' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated file'
        check 'Delete originals'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        !assert_html5_inputs_valid
      end
    end

    test 'should concatenate files as the basename provided is not in the correct format but fixed after error' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.concatenate_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated file'
        check 'Delete originals'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
        click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_text 'concatenated_file_1.fastq'
        assert_text 'concatenated_file_2.fastq'
        assert_selector 'table #attachments-table-body tr', count: 4
      end
    end

    test 'should be able to delete multiple attachments' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        find('table #attachments-table-body tr', text: 'test_file.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_A.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.delete_files_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file.fastq'
        assert_text 'test_file_A.fastq'
        click_on I18n.t('projects.samples.attachments.deletions.modal.submit_button')
        assert_html5_inputs_valid
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 0
        assert_no_text 'test_file.fastq'
        assert_no_text 'test_file_A.fastq'
        assert_text I18n.t('projects.samples.show.no_files')
        assert_text I18n.t('projects.samples.show.no_associated_files')
      end
      assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
    end

    test 'should be able to delete multiple attachments including paired files' do
      login_as users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleB)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      visit namespace_project_sample_url(namespace, project, sample)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 6
        find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
      end
      click_link I18n.t('projects.samples.show.delete_files_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text 'test_file_fwd_1.fastq'
        assert_text 'test_file_rev_1.fastq'
        assert_text 'test_file_fwd_2.fastq'
        assert_text 'test_file_rev_2.fastq'
        assert_text 'test_file_fwd_3.fastq'
        assert_text 'test_file_rev_3.fastq'
        assert_text 'test_file_D.fastq'
        click_on I18n.t('projects.samples.attachments.deletions.modal.submit_button')
      end
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        assert_no_text 'test_file_fwd_1.fastq'
        assert_no_text 'test_file_rev_1.fastq'
        assert_no_text 'test_file_fwd_2.fastq'
        assert_no_text 'test_file_rev_2.fastq'
        assert_no_text 'test_file_fwd_3.fastq'
        assert_no_text 'test_file_rev_3.fastq'
        assert_no_text 'test_file_D.fastq'
      end
      assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
    end

    test 'user can see delete buttons as owner' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_text I18n.t('projects.samples.show.delete_files_button'), count: 1
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        assert_text I18n.t('projects.samples.attachments.attachment.delete'), count: 2
      end
    end

    test 'user should not see sample attachment delete buttons if they are non-owner' do
      login_as users(:ryan_doe)
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_text I18n.t('projects.samples.show.delete_files_button'), count: 0
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body tr', count: 2
        assert_text I18n.t('projects.samples.attachments.attachment.delete'), count: 0
      end
    end

    test 'user with role >= Maintainer can see attachment checkboxes' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body input[type=checkbox]', count: 2
      end
    end

    test 'user with role < Maintainer should not see checkboxes' do
      login_as users(:ryan_doe)
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      within %(turbo-frame[id="table-listing"]) do
        assert_selector 'table #attachments-table-body input[type=checkbox]', count: 0
      end
    end

    test 'view sample metadata' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key')
        assert_selector 'table#metadata-table tbody tr', count: 2
        assert_text 'metadatafield1'
        assert_text 'value1'
        assert_text 'metadatafield2'
        assert_text 'value2'
      end
    end

    test 'update metadata key' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield1'
        assert_text 'value1'
        first('button.Viral-Dropdown--icon').click
        click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
      end

      within %(turbo-frame[id="sample_modal"]) do
        assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
        assert_selector 'input#sample_update_field_value_value1', count: 1
        find('input#sample_update_field_key_metadatafield1').fill_in with: 'newMetadataKey'
        click_on I18n.t('projects.samples.show.metadata.update.update')
      end

      assert_text I18n.t('projects.samples.metadata.fields.update.success')
      assert_no_text 'metadatafield1'
      assert_text 'newMetadataKey'
      assert_text 'value1'
    end

    test 'update metadata value' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield1'
        assert_text 'value1'
        first('button.Viral-Dropdown--icon').click
        click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
      end

      within %(turbo-frame[id="sample_modal"]) do
        assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
        assert_selector 'input#sample_update_field_value_value1', count: 1
        find('input#sample_update_field_value_value1').fill_in with: 'newMetadataValue'
        click_on I18n.t('projects.samples.show.metadata.update.update')
      end

      assert_text I18n.t('projects.samples.metadata.fields.update.success')
      assert_no_text 'value1'
      assert_text 'metadatafield1'
      assert_text 'newMetadataValue'
    end

    test 'update both metadata key and value at same time' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield1'
        assert_text 'value1'
        first('button.Viral-Dropdown--icon').click
        click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
      end

      within %(turbo-frame[id="sample_modal"]) do
        assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
        assert_selector 'input#sample_update_field_value_value1', count: 1
        find('input#sample_update_field_key_metadatafield1').fill_in with: 'newMetadataKey'
        find('input#sample_update_field_value_value1').fill_in with: 'newMetadataValue'
        click_on I18n.t('projects.samples.show.metadata.update.update')
      end

      assert_text I18n.t('projects.samples.metadata.fields.update.success')
      assert_no_text 'metadatafield1'
      assert_no_text 'value1'
      assert_text 'newMetadataKey'
      assert_text 'newMetadataValue'
    end

    test 'cannot update metadata key with key that already exists' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        first('button.Viral-Dropdown--icon').click
        click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
      end

      within %(turbo-frame[id="sample_modal"]) do
        assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
        assert_selector 'input#sample_update_field_value_value1', count: 1
        find('input#sample_update_field_key_metadatafield1').fill_in with: 'metadatafield2'
        click_on I18n.t('projects.samples.show.metadata.update.update')
      end

      assert_text I18n.t('services.samples.metadata.update_fields.key_exists', key: 'metadatafield2')
    end

    test 'user with access level < Maintainer cannot view update action' do
      sign_in users(:jane_doe)
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_no_text I18n.t('projects.samples.show.table_header.action')
        assert_no_selector 'button.Viral-Dropdown--icon'
        assert_text 'metadatafield1'
        assert_text 'value1'
        assert_text 'metadatafield2'
        assert_text 'value2'
      end
    end

    test 'user cannot update metadata added by an analysis' do
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @project31 = projects(:project31)
      @sample34 = samples(:sample34)

      visit namespace_project_sample_url(@subgroup12aa, @project31, @sample34)

      click_on I18n.t('projects.samples.show.tabs.metadata')

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield1'
        assert_text "#{I18n.t('models.sample.analysis')} 1"
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_no_text I18n.t('projects.samples.show.metadata.actions.dropdown.update')
        end
      end
    end

    test 'should be able to toggle metadata' do
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'label', text: I18n.t('projects.samples.index.search.metadata'), count: 1
      assert_selector 'table#samples-table thead tr th', count: 4
      find('label', text: I18n.t('projects.samples.index.search.metadata')).click
      assert_selector 'table#samples-table thead tr th', count: 6
      within first('table#samples-table tbody tr:nth-child(3)') do
        assert_text @sample3.name
        assert_selector 'td:nth-child(4)', text: 'value1'
        assert_selector 'td:nth-child(5)', text: 'value2'
      end
      find('label', text: I18n.t('projects.samples.index.search.metadata')).click
      assert_selector 'table#samples-table thead tr th', count: 4
    end

    test 'can sort samples by metadata column' do
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'label', text: I18n.t('projects.samples.index.search.metadata'), count: 1
      assert_selector 'table#samples-table thead tr th', count: 4
      find('label', text: I18n.t('projects.samples.index.search.metadata')).click
      assert_selector 'table#samples-table thead tr th', count: 6

      click_on 'metadatafield1'

      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample3.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample1.name
        assert_selector 'tr:last-child td:first-child', text: @sample2.name
      end

      click_on 'metadatafield2'

      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_up'
      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample3.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample1.name
        assert_selector 'tr:last-child td:first-child', text: @sample2.name
      end

      # toggling metadata again causes sort to be reset
      find('label', text: I18n.t('projects.samples.index.search.metadata')).click
      assert_selector 'table#samples-table thead tr th', count: 4

      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'
      assert_selector 'table#samples-table tbody tr', count: 3
      within first('tbody') do
        assert_selector 'tr:first-child td:first-child', text: @sample1.name
        assert_selector 'tr:nth-child(2) td:first-child', text: @sample2.name
        assert_selector 'tr:last-child td:first-child', text: @sample3.name
      end
    end

    test 'should not import metadata' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text I18n.t('projects.samples.index.import_metadata_button'), count: 0
    end

    test 'should import metadata via csv' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.success.description')
        click_on I18n.t('projects.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should import metadata via xls' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xls')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.success.description')
        click_on I18n.t('projects.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should import metadata via xlsx' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.success.description')
        click_on I18n.t('projects.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should not import metadata via invalid file type' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.invalid_file_extension')
      end
    end

    test 'should import metadata with ignore empty values' do
      namespace = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit namespace_project_samples_url(namespace, project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        check 'Ignore empty values'
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.success.description')
        click_on I18n.t('projects.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(namespace, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key')
        assert_selector 'table#metadata-table tbody tr', count: 3
        within first('tbody tr td:nth-child(1)') do
          assert_text 'metadatafield1'
        end
        within first('tbody tr td:nth-child(2)') do
          assert_text 'value1'
        end
      end
    end

    test 'should import metadata without ignore empty values' do
      namespace = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit namespace_project_samples_url(namespace, project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        assert_not find_field('Ignore empty values').checked?
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.success.description')
        click_on I18n.t('projects.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(namespace, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key')
        assert_selector 'table#metadata-table tbody tr', count: 2
        assert_no_text 'metadatafield1'
      end
    end

    test 'should not import metadata with duplicate header errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.duplicate_column_names')
      end
    end

    test 'should not import metadata with missing metadata row errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_row')
      end
    end

    test 'should not import metadata with missing metadata column errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_column')
      end
    end

    test 'should partially import metadata with missing sample errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.errors.description')
        click_on I18n.t('projects.samples.metadata.file_imports.errors.ok_button')
      end
    end

    test 'should not import metadata with analysis values' do
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      visit namespace_project_samples_url(subgroup12aa, project31)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('projects.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.metadata.file_imports.errors.description')
        click_on I18n.t('projects.samples.metadata.file_imports.errors.ok_button')
      end
    end

    test 'add new metadata' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.add_metadata')

      within %(turbo-frame[id="sample_modal"]) do
        find('input#key-0').fill_in with: 'metadatafield3'
        find('input#value-0').fill_in with: 'value3'
        click_on I18n.t('projects.samples.metadata.form.submit_button')
      end

      assert_text I18n.t('projects.samples.metadata.fields.create.success', keys: ['metadatafield3'].join(', '))

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield3'
        assert_text 'value3'
      end
    end

    test 'add existing metadata' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.add_metadata')

      within %(turbo-frame[id="sample_modal"]) do
        find('input#key-0').fill_in with: 'metadatafield1'
        find('input#value-0').fill_in with: 'value1'
        click_on I18n.t('projects.samples.metadata.form.submit_button')
      end

      assert_text I18n.t('projects.samples.metadata.fields.create.keys_exist', keys: ['metadatafield1'].join(', '))
    end

    test 'add both new and existing metadata' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.add_metadata')

      within %(turbo-frame[id="sample_modal"]) do
        find('input#key-0').fill_in with: 'metadatafield1'
        find('input#value-0').fill_in with: 'value1'
        click_on I18n.t('projects.samples.metadata.form.add_field_button')
        find('input#key-1').fill_in with: 'metadatafield3'
        find('input#value-1').fill_in with: 'value3'
        click_on I18n.t('projects.samples.metadata.form.submit_button')
      end

      assert_text I18n.t('projects.samples.metadata.fields.create.success', keys: ['metadatafield3'].join(', '))
      assert_text I18n.t('projects.samples.metadata.fields.create.keys_exist', keys: ['metadatafield1'].join(', '))

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield3'
        assert_text 'value3'
      end
    end

    test 'add new metadata which includes empty fields' do
      visit namespace_project_sample_url(@group12a, @project29, @sample32)

      click_on I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.add_metadata')

      within %(turbo-frame[id="sample_modal"]) do
        find('input#key-0').fill_in with: 'metadatafield3'
        find('input#value-0').fill_in with: 'value3'
        click_on I18n.t('projects.samples.metadata.form.add_field_button')
        find('input#key-1').fill_in with: 'metadatafield4'
        click_on I18n.t('projects.samples.metadata.form.add_field_button')
        find('input#value-2').fill_in with: 'value4'
        click_on I18n.t('projects.samples.metadata.form.add_field_button')
        find('input#key-3').fill_in with: 'metadatafield5'
        find('input#value-3').fill_in with: 'value5'
        click_on I18n.t('projects.samples.metadata.form.submit_button')
      end

      assert_text I18n.t('projects.samples.metadata.fields.create.success',
                         keys: %w[metadatafield3 metadatafield5].join(', '))

      within %(turbo-frame[id="table-listing"]) do
        assert_text 'metadatafield3'
        assert_text 'value3'
        assert_text 'metadatafield5'
        assert_text 'value5'
        assert_no_text 'metadatafield4'
        assert_no_text 'value4'
      end
    end

    # test 'add new metadata after deleting fields' do
    #   visit namespace_project_sample_url(@group12a, @project29, @sample32)

    #   click_on I18n.t('projects.samples.show.tabs.metadata')
    #   click_on I18n.t('projects.samples.show.add_metadata')

    #   within %(turbo-frame[id="sample_modal"]) do
    #     find('input#key-0').fill_in with: 'metadatafield3'
    #     find('input#value-0').fill_in with: 'value3'
    #     click_on I18n.t('projects.samples.metadata.form.add_field_button')
    #     find('input#key-1').fill_in with: 'metadatafield4'
    #     find('input#value-1').fill_in with: 'value4'
    #     click_on I18n.t('projects.samples.metadata.form.add_field_button')
    #     find('input#key-2').fill_in with: 'metadatafield5'
    #     find('input#value-2').fill_in with: 'value5'
    #     click_on I18n.t('projects.samples.metadata.form.add_field_button')
    #     find('input#key-3').fill_in with: 'metadatafield6'
    #     find('input#value-3').fill_in with: 'value6'
    #     assert_selector 'button#delete-field-1 span svg'
    #     find('button#delete-field-2 span svg').click
    #     find('button#delete-field-1 span svg').click
    #     click_on I18n.t('projects.samples.metadata.form.submit_button')
    #   end

    #   assert_text I18n.t('projects.samples.metadata.fields.create.success',
    #                      keys: %w[metadatafield3 metadatafield6].join(', '))

    # within %(turbo-frame[id="table-listing"]) do
    #   assert_text 'metadatafield3'
    #   assert_text 'value3'
    #   assert_text 'metadatafield6'
    #   assert_text 'value6'
    #   assert_no_text 'metadatafield4'
    #   assert_no_text 'value4'
    #   assert_no_text 'metadatafield5'
    #   assert_no_text 'value5'
    # end
    # end
  end
end
