# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample3 = samples(:sample30)
      @project = projects(:project1)
      @namespace = groups(:group_one)

      Project.reset_counters(@project.id, :samples_count)
    end

    test 'visiting the index' do
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector '#samples-table table tbody tr', count: 3
      assert_text @sample1.name
      assert_text @sample2.name
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

    test 'should destroy Sample from sample show page' do
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      assert_link text: I18n.t('projects.samples.index.remove_button'), count: 1
      click_link I18n.t(:'projects.samples.index.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                       project_name: @project.namespace.human_name)

      assert_no_selector '#samples-table table tbody tr', text: @sample1.name
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      assert_selector '#samples-table table tbody tr', count: 2
      within('tbody tr:first-child th') do
        assert_text @sample2.puid
      end
    end

    test 'should destroy Sample from sample listing page' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      table_row = find(:table_row, [@sample1.name])

      within table_row do
        click_link 'Remove'
      end

      within('dialog') do
        assert_text I18n.t('projects.samples.deletions.new_deletion_dialog.description', sample_name: @sample1.name)
        click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
      end

      assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                       project_name: @project.namespace.human_name)

      assert_no_selector '#samples-table table tbody tr', text: @sample1.puid
      assert_no_selector '#samples-table table tbody tr', text: @sample1.name
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      assert_selector '#samples-table table tbody tr', count: 2
      within('#samples-table table tbody tr:first-child th') do
        assert_text @sample2.puid
      end
    end

    test 'should transfer multiple samples' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                         '3')
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
    end

    test 'should transfer a single sample' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type="checkbox"]')[0].click
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text @sample1.name
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
    end

    test 'should not transfer samples with session storage cleared' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      Capybara.execute_script 'sessionStorage.clear()'
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_no_selector "turbo-frame[id='list_selections']"
        assert_text I18n.t('projects.samples.transfers.create.no_samples_transferred_error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
      end
    end

    test 'should not transfer samples' do
      project26 = projects(:project26)
      sample30 = samples(:sample30)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      check sample30.name
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          assert_text sample30.name
          assert_text sample30.puid
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project26.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_no_selector "turbo-frame[id='list_selections']"
        assert_text I18n.t('projects.samples.transfers.create.error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
      end
    end

    test 'should transfer some samples' do
      project25 = projects(:project25)
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_no_selector "turbo-frame[id='list_selections']"
        assert_text I18n.t('projects.samples.transfers.create.error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
      end
    end

    test 'should transfer samples for maintainer within hierarchy' do
      user = users(:joan_doe)
      login_as user
      project2 = projects(:project2)
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      user = users(:user28)
      login_as user
      namespace = groups(:group_hotel)
      project2 = projects(:projectHotel)
      Project.reset_counters(project2.id, :samples_count)
      visit namespace_project_samples_url(namespace, project2)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = project2.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        assert_no_selector 'option'
      end
    end

    test 'should not transfer samples for maintainer outside of hierarchy' do
      user = users(:joan_doe)
      login_as user

      # Project is a part of Group 8 and not a part of the current project hierarchy
      project32 = projects(:project32)
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        assert_no_selector "button[data-viral--select2-primary-param='#{project32.full_path}']"
      end
    end

    test 'should update pagination & selection during transfer samples' do
      namespace1 = groups(:group_one)
      namespace17 = groups(:group_seventeen)
      project38 = projects(:project38)
      project2 = projects(:project2)
      samples = [samples(:bulk_sample1), samples(:bulk_sample2)]

      Project.reset_counters(project38.id, :samples_count)
      visit namespace_project_samples_url(namespace17, project38)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 200,
                                                                           locale: @user.locale))

      click_button I18n.t(:'projects.samples.index.select_all_button')

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 200'
        assert_selector 'strong[data-selection-target="selected"]', text: '200'
      end

      click_link I18n.t('projects.samples.index.transfer_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER', '200')
        within %(turbo-frame[id="list_selections"]) do
          samples.pluck(:puid, :name).each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end

        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end

      # Check samples selected are [] and has the proper number of samples
      assert_text I18n.t(:'projects.samples.index.no_samples')

      Project.reset_counters(project2.id, :samples_count)
      visit namespace_project_samples_url(namespace1, project2)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 220,
                                                                           locale: @user.locale))

      click_button I18n.t(:'projects.samples.index.select_all_button')

      within 'tfoot' do
        sample_counts = all('strong')
        total_samples = sample_counts[0].text.to_i
        selected_samples = sample_counts[1].text.to_i
        assert selected_samples <= total_samples
      end
    end

    test 'empty state of transfer sample project selection' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').fill_in with: 'invalid project name or puid'
        assert_text I18n.t('projects.samples.transfers.dialog.empty_state')
      end
    end

    test 'no available destination projects to transfer samples' do
      sign_in users(:jean_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      Project.reset_counters(project.id, :samples_count)
      visit namespace_project_samples_url(namespace, project)
      within '#samples-table table tbody' do
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_selector "input[placeholder='#{I18n.t('projects.samples.transfers.dialog.no_available_projects')}']"
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

    test 'visiting the index should  not allow the current user only edit action' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('tbody tr:first-child') do
        assert_selector 'a', text: 'Edit', count: 1
        assert_selector 'a', text: 'Remove', count: 0
      end
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'visiting the index should not allow the current user any modification actions' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 0
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      assert_selector 'a', text: 'Edit', count: 0
      assert_selector 'a', text: 'Remove', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'can search the list of samples by name' do
      visit namespace_project_samples_url(@namespace, @project)
      filter_text = samples(:sample1).name[-3..-1]

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      assert_text @sample1.name
      assert_text @sample2.name

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_selector 'mark', text: filter_text
      assert_no_text @sample2.name
      assert_no_text @sample3.name

      # Refresh the page to ensure the search is still active
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_selector 'mark', text: filter_text
      assert_no_text @sample2.name
      assert_no_text @sample3.name
    end

    test 'can change pagination and then filter by name' do
      visit namespace_project_samples_url(@namespace, @project)

      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      assert_selector 'div#limit-component button div span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      assert_text @sample1.name
      assert_text @sample2.name

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector 'table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_selector 'div#limit-component button div span', text: '10'
    end

    test 'can change pagination and then toggle metadata' do
      visit namespace_project_samples_url(@namespace, @project)

      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      assert_selector 'div#limit-component button div span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      assert_selector '#samples-table table thead tr th', count: 6

      assert_selector 'label', text: I18n.t('projects.samples.shared.metadata_toggle.label'), count: 1
      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      assert_selector '#samples-table table thead tr th', count: 8
      assert_selector 'div#limit-component button div span', text: '10'
    end

    test 'can sort samples by column' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on 'Sample ID'

      assert_selector 'table thead th:first-child svg.icon-arrow_up'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] < puids[n + 1]
      end

      click_on 'Sample ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_down'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] > puids[n + 1]
      end

      click_on 'Sample Name'

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample3.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample3.name
      end

      click_on 'Sample Name'

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample3.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample3.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample1.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample1.name
      end

      click_on 'Created'

      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_up'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample3.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample3.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample1.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample1.name
      end

      click_on 'Created'

      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample3.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample3.name
      end

      click_on 'Last Updated'

      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample3.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample3.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample1.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample1.name
      end

      click_on 'Last Updated'

      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_down'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample3.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample3.name
      end
    end

    test 'can filter and then sort the list of samples by name' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child td:nth-child(2)') do
        assert_text @sample1.name
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_text @sample1.puid
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      assert_selector '#samples-table table tbody tr', count: 1
      within('#samples-table table tbody tr td:nth-child(2)') do
        assert_text @sample1.name
      end
    end

    test 'can filter and then sort the list of samples by puid' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_text @sample1.puid
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name

      click_on 'Sample ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_up'

      assert_selector '#samples-table table tbody tr', count: 1
      within('#samples-table table tbody tr th') do
        assert_text @sample1.puid
      end

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector '#samples-table table tbody tr', count: 1
      within('tbody tr th') do
        assert_text @sample1.puid
      end
    end

    test 'can sort and then filter the list of samples by name' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child td:nth-child(2)') do
        assert_text @sample1.name
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'

      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child td:nth-child(2)') do
        assert_text @sample3.name
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_text @sample1.puid
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name

      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_text @sample1.puid
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name
    end

    test 'can sort and then filter the list of samples by puid' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'

      assert_selector '#samples-table table tbody tr', count: 3
      within('#samples-table table tbody tr:first-child th') do
        assert_text @sample3.puid
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table tbody tr', count: 1
      assert_text @sample1.puid
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample3.name
    end

    test 'should be able to toggle metadata' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector '#samples-table table thead tr th', count: 6

      click_on 'Last Updated'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'

      assert_selector 'label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label'), count: 1
      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click

      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table tbody tr:first-child') do
        assert_text @sample3.name
        assert_selector 'td:nth-child(6)', text: 'value1'
        assert_selector 'td:nth-child(7)', text: 'value2'
      end
      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 6
    end

    test 'can sort samples by metadata column' do
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'label', text: I18n.t('projects.samples.shared.metadata_toggle.label'), count: 1
      assert_selector '#samples-table table thead tr th', count: 6
      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8

      within 'div.overflow-auto' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end

      click_on 'metadatafield1'

      assert_selector 'table thead th:nth-child(6) svg.icon-arrow_up'
      assert_selector '#samples-table table tbody tr', count: 3
      within('tbody') do
        assert_selector 'tr:first-child th', text: @sample3.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample3.name
        assert_selector 'tr:nth-child(2) th', text: @sample1.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:last-child th', text: @sample2.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample2.name
      end

      # toggling metadata again causes sort to be reset
      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 6

      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_down'
      assert_selector '#samples-table table tbody tr', count: 3
      within('tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample3.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample3.name
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
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should import metadata via xls' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xls')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should import metadata via xlsx' do
      visit namespace_project_samples_url(@namespace, @project)

      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8

      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first

      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
        find('#file_import_sample_id_column', wait: 2).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_selector 'table thead tr th', count: 10
    end

    test 'should not import metadata via invalid file type' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
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
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        check 'Ignore empty values'
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(namespace, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key').upcase
        assert_selector 'table#metadata-table tbody tr', count: 3
        within('table#metadata-table tbody tr:first-child td:nth-child(2)') do
          assert_text 'metadatafield1'
        end
        within('table#metadata-table tbody tr:first-child td:nth-child(3)') do
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
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        assert_not find_field('Ignore empty values').checked?
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(namespace, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key').upcase
        assert_selector 'table#metadata-table tbody tr', count: 2
        assert_no_text 'metadatafield1'
      end
    end

    test 'should not import metadata with duplicate header errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.duplicate_column_names')
      end
    end

    test 'should not import metadata with missing metadata row errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_row')
      end
    end

    test 'should not import metadata with missing metadata column errors' do
      visit namespace_project_samples_url(@namespace, @project)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="import_metadata_dialog_alert"]) do
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_column')
      end
    end

    test 'should partially import metadata with missing sample errors' do
      visit namespace_project_samples_url(@namespace, @project)

      find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8

      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end
      assert_selector '#samples-table table thead tr th', count: 9
    end

    test 'should not import metadata with analysis values' do
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      Project.reset_counters(project31.id, :samples_count)
      visit namespace_project_samples_url(subgroup12aa, project31)
      click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end
    end

    test 'user with maintainer access should be able to see the clone samples button' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.clone_button'), count: 1
    end

    test 'user with guest access should not be able to see the clone samples button' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.clone_button'), count: 0
    end

    test 'should clone multiple samples' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t(
          'projects.samples.clones.dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      assert_text I18n.t('projects.samples.clones.create.success')
    end

    test 'should clone single sample' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type="checkbox"]')[0].click
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.clones.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text @sample1.name
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      assert_text I18n.t('projects.samples.clones.create.success')
    end

    test 'should not clone samples with session storage cleared' do
      project2 = projects(:project2)
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      Capybara.execute_script 'sessionStorage.clear()'
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_no_selector "turbo-frame[id='list_selections']"
        assert_text I18n.t('projects.samples.clones.create.no_samples_cloned_error')
        errors = project2.errors.full_messages_for(:base)
        errors.each { |error| assert_text error }
        click_on I18n.t('projects.samples.shared.errors.ok_button')
      end
    end

    test 'should not clone some samples' do
      project25 = projects(:project25)
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('projects.samples.clones.create.error')
        errors = @project.errors.full_messages_for(:samples)
        errors.each { |error| assert_text error }
        click_on I18n.t('projects.samples.shared.errors.ok_button')
      end
    end

    test 'empty state of clone sample project selection' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        within %(turbo-frame[id="list_selections"]) do
          samples = @project.samples.pluck(:puid, :name)
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').fill_in with: 'invalid project name or puid'
        assert_text I18n.t('projects.samples.clones.dialog.empty_state')
      end
    end

    test 'no available destination projects to clone samples' do
      sign_in users(:jean_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      Project.reset_counters(project.id, :samples_count)
      visit namespace_project_samples_url(namespace, project)
      within '#samples-table table tbody' do
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.clone_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert "input[placeholder='#{I18n.t('projects.samples.clones.dialog.no_available_projects')}']"
      end
    end

    test 'filtering samples by list of sample puids' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector 'tr th', text: @sample1.puid
        assert_selector 'tr th', text: @sample2.puid
      end
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        fill_in I18n.t(:'components.list_filter.description'), with: "#{@sample1.puid}, #{@sample2.puid}"
        assert_selector 'span.label', count: 1
        assert_selector 'span.label', text: @sample1.puid
        find("input[name='q[name_or_puid_in][]']").text @sample2.puid
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
      end
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        click_button I18n.t(:'components.list_filter.clear')
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
      end
    end

    test 'selecting / deselecting all samples' do
      visit namespace_project_samples_url(@namespace, @project)
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '2'
      end
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      click_button I18n.t(:'projects.samples.index.deselect_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
    end

    test 'selecting / deselecting a page of samples' do
      visit namespace_project_samples_url(@namespace, @project)
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '2'
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
    end

    test 'selecting samples while filtering' do
      visit namespace_project_samples_url(@namespace, @project)
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name
      find('input.t-search-component').native.send_keys(:return)

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 1
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end

      click_button I18n.t(:'projects.samples.index.select_all_button')

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 1
      end
      within 'tfoot' do
        assert_text 'Samples: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: ' '
      find('input.t-search-component').native.send_keys(:return)

      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
    end

    test 'action links are disabled when a project does not contain any samples' do
      login_as users(:empty_doe)

      visit namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                          project_id: projects(:empty_project).path)

      assert_no_button I18n.t(:'projects.samples.index.clone_button')
      assert_no_button I18n.t(:'projects.samples.index.transfer_button')
      assert_text I18n.t('projects.samples.index.create_export_button.label')
      assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                      text: I18n.t('projects.samples.index.create_export_button.label')
    end

    test 'action links are disabled when a group does not contain any projects with samples' do
      login_as users(:empty_doe)

      visit group_samples_url(groups(:empty_group))

      assert_no_button I18n.t(:'projects.samples.index.clone_button')
      assert_no_button I18n.t(:'projects.samples.index.transfer_button')
      assert_text I18n.t('projects.samples.index.create_export_button.label')
      assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                      text: I18n.t('projects.samples.index.create_export_button.label')
    end

    def retrieve_puids
      puids = []
      within('#samples-table table tbody') do
        (1..3).each do |n|
          puids << first("tr:nth-child(#{n}) th").text
        end
      end
      puids
    end

    test 'delete multiple samples' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_text @sample1.name
        assert_text @sample2.name
        assert_text @sample3.name
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end
      click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
        assert_text I18n.t(
          'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
        assert_text @sample1.name
        assert_text @sample1.puid
        assert_text @sample2.name
        assert_text @sample2.puid
        assert_text @sample3.name
        assert_text @sample3.puid

        click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
      end
      assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

      within 'div[role="alert"]' do
        assert_text I18n.t('projects.samples.index.no_samples')
        assert_text I18n.t('projects.samples.index.no_associated_samples')
      end
    end

    test 'delete single sample with checkbox and delete samples button' do
      visit namespace_project_samples_url(@namespace, @project)
      within('tbody') do
        assert_selector 'tr', count: 3
        assert_text @sample1.name
        assert_text @sample2.name
        assert_text @sample3.name
        within 'tr:first-child' do
          all('input[type="checkbox"]')[0].click
        end
      end
      click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
        assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.description.singular',
                           sample_name: @sample1.name)
        within %(turbo-frame[id="list_selections"]) do
          assert_text @sample1.puid
        end

        click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
      end

      assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

      within 'tbody' do
        assert_selector 'tr', count: 2
        assert_no_text @sample1.name
        assert_text @sample2.name
        assert_text @sample3.name
      end
    end

    test 'delete single sample with remove link while all samples selected followed by multiple deletion' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_text @sample1.name
        assert_text @sample2.name
        assert_text @sample3.name
        all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
      end

      assert find('input#select-page').checked?

      within '#samples-table table tbody tr:first-child' do
        click_link I18n.t('projects.samples.index.remove_button')
      end

      within 'dialog' do
        click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        assert_no_text @sample1.name
        assert all('input[type="checkbox"]')[0].checked?
        assert all('input[type="checkbox"]')[1].checked?
      end

      assert find('input#select-page').checked?

      click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
        assert_text I18n.t(
          'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '2'
        assert_text @sample2.name
        assert_text @sample3.name
        assert_no_text @sample1.name
        click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
      end
      assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

      within 'div[role="alert"]' do
        assert_text I18n.t('projects.samples.index.no_samples')
        assert_text I18n.t('projects.samples.index.no_associated_samples')
      end

      assert_selector 'a.cursor-not-allowed.pointer-events-none', count: 4
      assert_selector 'button.cursor-not-allowed.pointer-events-none', count: 1
    end

    test 'can filter by large list of sample names or ids' do
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector 'tr th', text: @sample1.puid
        assert_selector 'tr th', text: @sample2.puid
      end
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do |dialog|
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        fill_in I18n.t(:'components.list_filter.description'), with: long_filter_text
        assert_selector 'span.label', count: 500
        dialog.scroll_to(dialog.find('button', text: I18n.t(:'components.list_filter.apply')), align: :bottom)
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
      end
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do |dialog|
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        dialog.scroll_to dialog.find('button', text: I18n.t(:'components.list_filter.apply'))

        click_button I18n.t(:'components.list_filter.clear')
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
      end
    end

    def long_filter_text
      text = (1..500).map { |n| "sample#{n}" }.join(', ')
      "#{text}, #{@sample1.name}" # Need to comma to force the tag to be created
    end
  end
end
