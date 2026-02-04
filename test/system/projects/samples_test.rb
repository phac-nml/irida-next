# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      Flipper.enable(:advanced_search_with_auto_complete)
      Flipper.enable(:virtualized_samples_table)

      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample30 = samples(:sample30)
      @sample32 = samples(:sample32)
      @project = projects(:project1)
      @project2 = projects(:project2)
      @project29 = projects(:project29)
      @namespace = groups(:group_one)
      @subgroup12a = groups(:subgroup_twelve_a)
    end

    test 'samples index table' do
      freeze_time
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')

      # samples table
      # headers
      assert_selector 'table thead tr th:first-child',
                      text: I18n.t('components.samples.virtualized_table_component.puid').upcase
      assert_selector 'table thead tr th:nth-child(2)',
                      text: I18n.t('components.samples.virtualized_table_component.name').upcase
      assert_selector 'table thead tr th:nth-child(3)',
                      text: I18n.t('components.samples.virtualized_table_component.created_at').upcase
      assert_selector 'table thead tr th:nth-child(4)',
                      text: I18n.t('components.samples.virtualized_table_component.updated_at').upcase
      assert_selector 'table thead tr th:nth-child(5)',
                      text: I18n.t('components.samples.virtualized_table_component.attachments_updated_at').upcase
      # rows
      assert_selector 'table tbody tr', count: 3
      # row contents
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(3)",
                      text: I18n.l(@sample1.created_at.to_date, format: :long)
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(4)", text: '3 hours ago'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(5)", text: '2 hours ago'
      # actions tested by role in separate test
    end

    test 'User with role >= Analyst sees select and deselect buttons for samples table' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_selector 'form#select-all-form'
      assert_selector 'form#deselect-all-form'
    end

    test 'User with role < Analyst does not see select and deselect buttons for samples table' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_no_selector 'form#select-all-form'
      assert_no_selector 'form#deselect-all-form'
    end

    test 'User with role >= Analyst sees sample table checkboxes' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_selector 'input#select-page'
      assert_selector "input##{dom_id(@sample1, :checkbox)}"
    end

    test 'User with role < Analyst does not see sample table checkboxes' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_no_selector 'input#select-page'
      assert_no_selector "input##{dom_id(@sample1, :checkbox)}"
    end

    test 'User with role >= Analyst sees workflow execution link' do
      user = users(:james_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      assert_selector 'span',
                      text: I18n.t('projects.samples.index.workflows.button_sr', locale: user.locale)
    end

    test 'User with role < Analyst does not see workflow execution link' do
      user = users(:ryan_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      assert_no_selector 'span', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role >= Analyst sees sample actions dropdown' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role < Analyst does not see sample actions dropdown' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_no_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role >= Analyst sees create export button' do
      user = users(:james_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label', locale: user.locale)
      assert_selector 'button',
                      text: I18n.t('shared.samples.actions_dropdown.linelist_export', locale: user.locale)
      assert_selector 'button',
                      text: I18n.t('shared.samples.actions_dropdown.sample_export', locale: user.locale)
    end

    test 'User with role < Analyst does not see create export button' do
      user = users(:ryan_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      assert_no_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
    end

    test 'User with role >= Maintainer sees import metadata button' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
    end

    test 'User with role == Analyst sees sample actions dropdown but not import metadata button' do
      login_as users(:michelle_doe)
      project = projects(:project24)
      visit namespace_project_samples_url(project.parent, project)

      assert_text I18n.t('projects.samples.index.no_associated_samples')

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_no_selector 'button', text: I18n.t('shared.samples.actions_dropdown.import_metadata')
    end

    test 'User with role >= Maintainer sees new sample button' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.new_sample')
    end

    test 'User with role < Maintainer does not see new sample button' do
      user = users(:michelle_doe)
      project = projects(:project24)
      login_as user
      visit namespace_project_samples_url(project.parent, project)

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_no_selector 'button', text: I18n.t('shared.samples.actions_dropdown.new_sample')
    end

    test 'User with role == Owner sees delete samples button' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
    end

    test 'User with role < Owner does not see delete samples button' do
      user = users(:michelle_doe)
      project = projects(:project24)
      login_as user
      visit namespace_project_samples_url(project.parent, project)

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_no_selector 'button', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
    end

    test 'cannot access project samples' do
      login_as users(:user_no_access)

      visit namespace_project_samples_url(@namespace, @project)

      assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
    end

    test 'create sample' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # sample does not currently exist
      assert_no_selector 'table tbody tr td:nth-child(2)', text: 'New Name'
      ### SETUP END ###

      ### ACTIONS START ###
      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.new_sample')

      # fill new sample fields
      fill_in I18n.t('activerecord.attributes.sample.description'), with: 'A sample description'
      fill_in I18n.t('activerecord.attributes.sample.name'), with: 'New Name'
      click_button I18n.t('helpers.submit.sample.create', model: Sample.model_name.human,
                                                          default: :'helpers.submit.create')
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('projects.samples.create.success')
      # verify redirect to sample show page after successful sample creation
      assert_selector 'h1', text: 'New Name'
      assert_selector 'span', text: 'A sample description'

      # verify sample exists in samples table
      click_link 'Samples', match: :first
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr td:nth-child(2)', text: 'New Name'
      ### VERIFY END ###
    end

    test 'create sample with missing name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.new_sample')

      # fill new sample fields
      fill_in I18n.t('activerecord.attributes.sample.description'), with: 'A sample description'
      fill_in I18n.t('activerecord.attributes.sample.name'), with: ''
      click_button I18n.t('helpers.submit.sample.create', model: Sample.model_name.human,
                                                          default: :'helpers.submit.create')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text "Name can't be blank"
      assert_text 'Name is too short (minimum is 3 characters)'
      ### VERIFY END ###
    end

    test 'create sample with existing name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.new_sample')

      # fill new sample fields
      fill_in I18n.t('activerecord.attributes.sample.description'), with: 'A sample description'
      fill_in I18n.t('activerecord.attributes.sample.name'), with: @sample1.name
      click_button I18n.t('helpers.submit.sample.create', model: Sample.model_name.human,
                                                          default: :'helpers.submit.create')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text 'Name has already been taken'
      ### VERIFY END ###
    end

    test 'edit sample' do
      ### SETUP START ###
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      # verify header has loaded to prevent flakes
      assert_selector 'h1', text: @sample1.name
      ### SETUP END ###

      ### ACTIONS START ###
      # nav to edit sample page
      click_on I18n.t('projects.samples.show.edit_button')

      # verify current sample doesn't have with new properties that will be used
      assert_no_text 'A new description'
      assert_no_text 'New Sample Name'
      # change current sample properties
      fill_in 'Description', with: 'A new description'
      fill_in 'Name', with: 'New Sample Name'
      click_button I18n.t('projects.samples.edit.submit_button')
      ### ACTIONS END ###

      ### results start ###
      # success flash msg
      assert_text I18n.t('projects.samples.update.success')

      # verify redirect to sample show page and updated sample state
      assert_selector 'h1', text: 'New Sample Name'
      assert_text 'A new description'
      ### results end ###
    end

    test 'edit sample with blank name' do
      ### SETUP START ###
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      # verify header has loaded to prevent flakes
      assert_selector 'h1', text: @sample1.name
      ### SETUP END ###

      ### ACTIONS START ###
      # nav to edit sample page
      click_on I18n.t('projects.samples.show.edit_button')

      # verify current sample doesn't have with new properties that will be used
      assert_no_text 'A new description'
      assert_no_text 'New Sample Name'
      # change current sample properties
      fill_in 'Description', with: 'A new description'
      fill_in 'Name', with: ''
      click_button I18n.t('projects.samples.edit.submit_button')
      ### ACTIONS END ###

      ### results start ###
      assert_text "Name can't be blank"
      assert_text 'Name is too short (minimum is 3 characters)'
      ### results end ###
    end

    test 'edit sample to match existing sample' do
      ### SETUP START ###
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      # verify header has loaded to prevent flakes
      assert_selector 'h1', text: @sample1.name
      ### SETUP END ###

      ### ACTIONS START ###
      # nav to edit sample page
      click_on I18n.t('projects.samples.show.edit_button')

      # verify current sample doesn't have with new properties that will be used
      assert_no_text 'A new description'
      assert_no_text 'New Sample Name'
      # change current sample properties
      fill_in 'Description', with: 'A new description'
      fill_in 'Name', with: @sample2.name
      click_on I18n.t('projects.samples.edit.submit_button')
      ### ACTIONS END ###

      ### results start ###
      assert_text 'Name has already been taken'
      ### results end ###
    end

    test 'destroy sample from sample show page' do
      ### SETUP START ###
      # nav to samples index and verify sample exists within table
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      # select all samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 3
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector 'table tbody tr', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'

      # nav to sample show
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      # verify header has loaded to prevent flakes
      assert_selector 'h1', text: @sample1.name
      ### SETUP END ###

      ### ACTIONS START ##
      # remove sample
      click_button I18n.t('common.actions.remove')

      assert_selector 'dialog h1', text: I18n.t(:'samples.deletions.destroy_single_confirmation_dialog.title')
      within('dialog[open]') do
        click_button I18n.t('common.actions.remove')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('samples.deletions.destroy.success', count: 1)
      # redirected to samples index
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      # remaining samples still appear selected
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked',
                      count: 2
      # remaining samples still appear on table
      assert_selector 'table tbody tr', count: 2
      # deleted sample row no longer exists
      assert_no_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 2'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '2'
      ### VERIFY END ###
    end

    test 'transfer dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')

      ### VERIFY START ###
      within('#list_selections') do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with plural description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      within('dialog[open]') do
        assert_text I18n.t('samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                '3')
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with singular description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      find('table tbody tr:first-child th input[type="checkbox"]').click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      within('dialog[open]') do
        assert_text I18n.t('samples.transfers.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'transfer samples' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      # show destination project has 20 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: @user.locale))
      # originating project has 3 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      within('#list_selections') do
        samples.each do |sample|
          # additional asserts to help prevent select2 actions below from flaking
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      # select destination project
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')
      # flash msg
      assert_text I18n.t('samples.transfers.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'dialog[open]'
      # originating project no longer has samples
      assert_text I18n.t('projects.samples.index.no_samples')

      # destination project received transferred samples
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 23,
                                                                                      locale: @user.locale))

      samples.each do |sample|
        assert_selector 'table tbody tr th:first-child', text: sample[0]
        assert_selector 'table tbody tr td:nth-child(2)', text: sample[1]
      end
      ### VERIFY END ###
    end

    test 'dialog close button hidden during transfer samples' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      # originating project has 3 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t('common.controls.select_all')
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      # close button available before confirming
      assert_selector 'dialog button.dialog--close'
      within('#list_selections') do
        samples.each do |sample|
          # additional asserts to help prevent select2 actions below from flaking
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      # select destination project
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')

      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      assert_no_selector 'button.dialog--close'
      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')
      # flash msg
      assert_text I18n.t('samples.transfers.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'dialog[open]'
      ### VERIFY END ###
    end

    test 'should not transfer samples with session storage cleared' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      # launch transfer dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # samples listing should no longer appear in dialog
      assert_no_selector '#list_selections'
      # error msg displayed in dialog
      assert_text I18n.t('samples.transfers.create.no_samples_transferred_error')
      ### VERIFY END ###
    end

    test 'transfer samples with and without same name in destination project' do
      # only samples without a matching name to samples in destination project will transfer

      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      namespace = groups(:subgroup1)
      project25 = projects(:project25)

      # verify only 2 samples exist in destination project
      visit namespace_project_samples_url(namespace, project25)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      # 3 samples in originating project
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      within('#list_selections') do
        samples.each do |sample|
          # additional asserts to help prevent select2 actions below from flaking
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      find('input.select2-input').click
      find("li[data-value='#{project25.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # error messages in dialog
      assert_text I18n.t('samples.transfers.create.error')
      # colon is removed from translation in UI
      assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: @sample30.puid,
                                                                    sample_name: @sample30.name).gsub(':', '')

      click_button I18n.t('shared.samples.errors.ok_button')

      assert_no_selector 'dialog[open]'

      # verify sample1 and 2 transferred, sample 30 did not
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      assert_no_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample30)}']"

      # destination project
      visit namespace_project_samples_url(namespace, project25)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "table tbody tr[id='#{dom_id(@sample30)}']"
      ### VERIFY END ###
    end

    test 'sample transfer button should not be available for maintainer of a user namespace project' do
      ### SETUP START ###
      login_as users(:micha_doe)

      namespace = namespaces_user_namespaces(:user31_namespace)
      project = projects(:projectUser31)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      ### SETUP END ### ##
      ## ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 1
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 1'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      ### ACTIONS END ### ##

      ### VERIFY START ###
      assert_no_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### VERIFY END ###
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      ### SETUP START ###
      login_as users(:user28)
      namespace = groups(:group_hotel)
      project = projects(:projectHotel)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 1
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 1'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      # no available destination projects
      assert_field placeholder: I18n.t('samples.transfers.dialog.no_available_projects'), disabled: true
      ### VERIFY END ###
    end

    test 'updating sample selection during transfer samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)

      # verify no samples currently selected in destination project
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'

      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select 1 sample to transfer
      find('table tbody tr:first-child th input[type="checkbox"]').click

      # verify 1 sample selected in originating project
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'

      # transfer sample
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      within('#list_selections') do
        # additional asserts to help prevent select2 actions below from flaking
        assert_text @sample1.name
        assert_text @sample1.puid
      end
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'dialog[open]'

      # verify no samples selected anymore
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "2 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'

      # verify destination project still has no selected samples and one additional sample
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "21 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
      ### VERIFY END ###
    end

    test 'empty state of transfer sample project selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'

      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
      # fill destination input
      find('input.select2-input').fill_in with: 'invalid project name or puid'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.transfers.dialog.empty_state')
      ### VERIFY END ###
    end

    test 'limit persists through filter and sort actions' do
      # tests limit change and that it persists through other actions (filter)
      ### SETUP START ###
      sample3 = samples(:sample3)
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### actions and VERIFY START ###
      within('div#limit-component') do
        # set table limit to 10
        select '10', from: 'limit'
      end

      # verify limit is set to 10
      assert_selector 'div#limit-component select option[selected]', text: '10'
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 20,
                                                                                      locale: @user.locale))
      # verify table consists of 10 samples per page
      assert_selector 'table tbody tr', count: 10

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: sample3.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # verify limit is still 10
      assert_selector 'div#limit-component select option[selected]', text: '10'

      # apply sort
      click_on I18n.t('components.samples.virtualized_table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # verify limit is still 10
      assert_selector 'div#limit-component select option[selected]', text: '10'
      ### actions and VERIFY END ###
    end

    test 'can sort samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTION and VERIFY START ###
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      # sort by name
      click_on I18n.t('components.samples.virtualized_table_component.name')

      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      assert_selector 'table tbody tr:last-child th', text: @sample30.puid
      assert_selector 'table tbody tr:last-child td:nth-child(2)', text: @sample30.name

      # change name sort direction
      click_on I18n.t('components.samples.virtualized_table_component.name')

      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      assert_selector 'table tbody tr:first-child th', text: @sample30.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample30.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      assert_selector 'table tbody tr:last-child th', text: @sample1.puid
      assert_selector 'table tbody tr:last-child td:nth-child(2)', text: @sample1.name
      ### ACTION and VERIFY END ###
    end

    test 'sort persists through limit and filter' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### actions and VERIFY START ###
      # apply sort
      click_on I18n.t('components.samples.virtualized_table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # set limit
      within('div#limit-component') do
        select '10', from: 'limit'
      end

      # verify sort is still applied
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # verify sort is still applied
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      ### actions and VERIFY END ###
    end

    test 'filter by name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample1 exists within table
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'filter by puid' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample2.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample2 exists within table
      assert_no_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'filter highlighting for sample name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: 'sample'
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify table still contains all samples
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # checks highlighting
      assert_selector 'mark', text: 'Sample', count: 3
      ### VERIFY END ###
    end

    test 'filter highlighting for sample puid' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify table only contains sample1
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      # checks highlighting
      assert_selector 'mark', text: @sample1.puid
      ### VERIFY END ###
    end

    test 'filter persists through sort and limit actions' do
      ### SETUP START ###
      filter_text = @sample1.name
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### ACTIONS and VERIFY START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: filter_text
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid

      # apply sort
      click_on I18n.t('components.samples.virtualized_table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # verify table still only contains sample1
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid

      # verify filter text is still in filter input
      assert_selector %(input[data-test-selector="search-field-input"]) do |input|
        assert_equal filter_text, input['value']
      end

      # set limit
      within('div#limit-component') do
        select '10', from: 'limit'
      end

      # verify table still only contains sample1
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid

      # verify filter text is still in filter input
      assert_selector %(input[data-test-selector="search-field-input"]) do |input|
        assert_equal filter_text, input['value']
      end
      ### VERIFY END ###
    end

    test 'filter persists through page refresh' do
      ### SETUP START ###
      filter_text = @sample1.name
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: filter_text
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid

      # refresh
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      # verify filter is still in input field
      assert_selector %(input[data-test-selector="search-field-input"]) do |input|
        assert_equal filter_text, input['value']
      end
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'sort persists through page refresh' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # apply sort
      click_on I18n.t('components.samples.virtualized_table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      assert_selector '#samples-table table tbody th:first-child', text: @sample1.puid
      # change sort order from default sorting
      click_on I18n.t('components.samples.virtualized_table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### ACTIONS END ###

      ### VERIFY START ###
      # refresh
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # verify sort is still enabled
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      # verify table ordering is still in sorted state
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'should import metadata via csv' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      # metadatafield1 and 2 already exist, 3 does not and will be added by the import
      assert_selector 'table thead tr th', text: 'METADATAFIELD1'
      assert_selector 'table thead tr th', text: 'METADATAFIELD2'
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD3'
      # sample 1 and 2 have no current value for metadatafield 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: ''
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')

      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # metadatafield3 added to header
      assert_selector 'table thead tr th', count: 8
      assert_selector 'table thead tr th', text: 'METADATAFIELD3'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: '10'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: '20'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(8)", text: '30'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(6)", text: '15'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(7)", text: '25'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(8)", text: '35'
      ### VERIFY END ###
    end

    test 'should import metadata via xls' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7
      # metadatafield 3 and 4 will be added by import
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD3'
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD4'
      # sample 1 and 2 have no current value for metadatafield 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(7)", text: ''
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')

      assert_field I18n.t(:'shared.samples.metadata.file_imports.dialog.sample_id_column')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 5

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield4'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield5'

      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # metadatafield3 and 4 added to header
      assert_selector 'table thead tr th', count: 9
      assert_selector 'table thead tr th', text: 'METADATAFIELD3'
      assert_selector 'table thead tr th', text: 'METADATAFIELD4'
      # new metadata values for sample 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: '10'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: '2024-01-04'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(8)", text: 'true'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(9)", text: 'A Test'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(6)", text: '15'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(7)", text: '2024-12-31'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(8)", text: 'false'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(9)", text: 'Another Test'
      ### VERIFY END ###
    end

    test 'should import metadata via xlsx' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector '#samples-table table thead tr th', count: 7
      # metadatafield 3 and 4 will be added by import
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD3'
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD4'
      # sample 1 and 2 have no current value for metadatafield 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(7)", text: ''
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 5

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield4'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield5'

      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # metadatafield3 and 4 added to header
      assert_selector 'table thead tr th', count: 9
      assert_selector 'table thead tr th', text: 'METADATAFIELD3'
      assert_selector 'table thead tr th', text: 'METADATAFIELD4'
      # sample 1 and 2 have no current value for metadatafield 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: '10'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: '2024-01-04'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(8)", text: 'true'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(9)", text: 'A Test'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(6)", text: '15'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(7)", text: '2024-12-31'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(8)", text: 'false'
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(9)", text: 'Another Test'
      ### VERIFY END ###
    end

    test 'verify metadata columns are hidden and unhidden during file selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      # find metadataColumns div container
      metadata_columns_element = find('div[data-metadata--file-import-target="metadataColumns"]', visible: :all)
      # verify by default it's hidden and has aria-hidden="true"
      assert_equal 'true', metadata_columns_element['aria-hidden']
      assert_no_selector 'div[data-metadata--file-import-target="metadataColumns"]'

      # verify after uploading file, metadata columns are shown and aria-hidden is removed
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
      assert_not metadata_columns_element['aria-hidden']
      assert_selector 'div[data-metadata--file-import-target="metadataColumns"]'

      # remove file and verify metadataColumns is hidden and aria-hidden="true" is re-added
      attach_file 'file_import[file]', nil
      assert_equal 'true', metadata_columns_element['aria-hidden']
      assert_no_selector 'div[data-metadata--file-import-target="metadataColumns"]'
    end

    test 'dialog close button is hidden during metadata import' do
      visit namespace_project_samples_url(@namespace, @project)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      # dialog close button available when selecting params
      assert_selector 'dialog button.dialog--close'

      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
      assert_field I18n.t('shared.samples.metadata.file_imports.dialog.sample_id_column')
      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      # dialog button hidden while importing
      assert_no_selector 'dialog button.dialog--close'
      ### VERIFY END ###
    end

    test 'should not import metadata via invalid file type' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')

      assert_no_selector 'dialog div', text: I18n.t('shared.samples.metadata.file_imports.dialog.metadata')
      assert_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button'), disabled: true
      ### ACTIONS AND VERIFY END ###
    end

    test 'should import metadata with ignore empty values' do
      # enabled ignore empty values will leave sample metadata values unchanged
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # value for metadatafield1, which is blank on the csv to import and will be left unchanged after import
      assert_selector "table tbody tr[id='#{dom_id(@sample32)}'] td:nth-child(6)", text: 'value1'
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
      assert_selector 'p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_selector 'p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      # leave ignore empty values enabled
      assert find('input#file_import_ignore_empty_values').checked?
      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_button I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # unchanged value
      assert_selector "table tbody tr[id='#{dom_id(@sample32)}'] td:nth-child(6)", text: 'value1'
      ### VERIFY END ###
    end

    test 'should import metadata without ignore empty values' do
      # disabled ignore empty values will delete any metadata values that are empty on the import
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # value for metadatafield1, which is blank on the csv to import and will be deleted by the import
      assert_selector "table tbody tr[id='#{dom_id(@sample32)}'] td:nth-child(6)", text: 'value1'
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      # disable ignore empty values
      find('input#file_import_ignore_empty_values').click
      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_button I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # value is deleted for metadatafield1
      assert_selector "table tbody tr[id='#{dom_id(@sample32)}'] td:nth-child(6)", text: ''
      ### VERIFY END ###
    end

    test 'imported metadata with whitespaces can still be interacted with within import dialog and imported' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_whitespaces.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 4

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 3'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 4'

      # click on "metadata field 1" and then remove it
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 1').click

      click_button I18n.t('common.actions.remove')

      # verify only "metadata field 1" was removed
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 1
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata field 1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 3'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 4'

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_button I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # verify after import only metadata fields "metadata field 2/3/4" were imported
      assert_selector 'table thead tr th', count: 10
      assert_selector 'table thead tr th', text: 'METADATA FIELD 2'
      assert_selector 'table thead tr th', text: 'METADATA FIELD 3'
      assert_selector 'table thead tr th', text: 'METADATA FIELD 4'
      assert_no_selector 'table thead tr th', text: 'METADATA FIELD 1'
      ### ACTIONS AND VERIFY END ###
    end

    test 'should not import metadata with duplicate header errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 4

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3', count: 2

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # error msg
      assert_text I18n.t('services.spreadsheet_import.duplicate_column_names')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata row errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # error msg
      assert_text I18n.t('services.spreadsheet_import.missing_data_row')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata column errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button'), disabled: true
      ### VERIFY END ###
    end

    test 'should partially import metadata with missing sample errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7
      # metadatafield1 and 2 already exist, 3 does not and will be added by the import
      assert_selector 'table thead tr th', text: 'METADATAFIELD1'
      assert_selector 'table thead tr th', text: 'METADATAFIELD2'
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD3'
      # sample 1 has no current value for metadatafield 1 and 2
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: ''
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: ''
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # sample 3 does not exist in current project
      assert_text I18n.t('services.samples.metadata.import_file.sample_not_found_within_project',
                         sample_puid: 'Project 2 Sample 3')
      click_button I18n.t('shared.samples.metadata.file_imports.errors.ok_button')

      assert_no_selector 'dialog[open]'

      # metadata still imported
      assert_selector 'table thead tr th', count: 8
      assert_selector 'table thead tr th', text: 'METADATAFIELD3'
      # sample 1 still imported even though sample3 (from import) does not exist
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(6)", text: '10'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(7)", text: '20'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(8)", text: '30'
      ### VERIFY END ###
    end

    test 'should not import metadata with analysis values' do
      ### SETUP START ###
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      visit namespace_project_samples_url(subgroup12aa, project31)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # metadata that does not overwriting analysis values will still be added
      assert_selector 'table thead tr th', count: 7
      assert_no_selector 'table thead tr th', text: 'METADATAFIELD3'
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 2

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                         sample_name: samples(:sample34).name, metadata_fields: 'metadatafield1')
      click_button I18n.t('shared.samples.metadata.file_imports.errors.ok_button')

      assert_no_selector 'dialog[open]'

      # metadatafield3 still added
      assert_selector 'table thead tr th', count: 8
      assert_selector 'table thead tr th', text: 'METADATAFIELD3'
      # new metadata value
      assert_selector "table tbody tr[id='#{dom_id(samples(:sample34))}'] td:nth-child(8)", text: '20'
      ### VERIFY END ###
    end

    test 'uploading spreadsheet with no viable metadata should display error' do
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      visit namespace_project_samples_url(subgroup12aa, project31)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv')

      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.no_valid_metadata')
      assert_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button'), disabled: true
    end

    test 'should not import metadata from ignored header values' do
      visit namespace_project_samples_url(@namespace, @project)

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # description and project_puid metadata headers do not exist
      assert_selector 'table thead tr th', count: 7
      assert_selector 'table thead tr th', text: 'METADATAFIELD1'
      assert_no_selector 'table thead tr th', text: 'DESCRIPTION'
      assert_no_selector 'table thead tr th', text: 'PROJECT_PUID'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_ignored_headers.csv')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.metadata.file_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield3'

      click_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_button I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      assert_selector '#samples-table table thead tr th', count: 8
      assert_selector '#samples-table table thead tr th', text: 'METADATAFIELD3'
      assert_no_selector '#samples-table table thead tr th', text: 'DESCRIPTION'
      assert_no_selector '#samples-table table thead tr th', text: 'PROJECT_PUID'
    end

    test 'should import samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))
      click_button I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      click_button I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # added 2 new samples
      assert_selector 'table tbody tr', count: 5
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      ### VERIFY END ###
    end

    test 'should import partial data when some rows are invalid' do
      # Using short sample name to test this.
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(
        I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )

      assert_selector 'table tbody tr', count: 3
      assert_no_selector 'table tbody tr td:nth-child(2)', text: 'my new sample'
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_short_sample_name.csv'))
      assert_field I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column')
      click_button I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      # problem message
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.problems')
      # problem table
      within('#problems_table table tbody') do
        # has 1 problem
        assert_selector 'tr', count: 1
        assert_text 'm sample name is too short (minimum is 3 characters)'
      end
      click_button I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # added 1 new sample
      assert_selector 'table tbody tr', count: 4
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample'
      ### VERIFY END ###
    end

    test 'should import samples with metadata that have whitespaces' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(
        I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )
      assert_selector 'table tbody tr', count: 3
      assert_no_selector 'table tbody tr td:nth-child(2)', text: 'my new sample 1'
      assert_no_selector 'table tbody tr td:nth-child(2)', text: 'my new sample 2'

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead th', count: 7
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/valid_with_whitespaces.csv'))
      assert_text I18n.t(:'shared.samples.spreadsheet_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.spreadsheet_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 3'

      # click on "metadata field 1" and then remove it
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 1').click

      click_button I18n.t('common.actions.remove')

      # verify only "metadata field 1" was removed
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 1
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 2

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata field 1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata field 3'

      click_button I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      click_button I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # refresh to see new samples
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(
        I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 5, count: 5, locale: @user.locale)
      )
      assert_selector 'table thead tr th', count: 9
      # added 2 new samples
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table thead tr th', text: 'METADATA FIELD 2'
      assert_selector 'table thead tr th', text: 'METADATA FIELD 3'
      assert_no_selector 'table thead tr th', text: 'METADATA FIELD 1'
      ### VERIFY END ###
    end

    test 'should not import samples when file malformed' do
      # Using duplicate file header to test this.
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(
        I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )

      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_duplicate_header.csv'))
      click_button I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # error msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.errors.description')
      click_button I18n.t('shared.samples.spreadsheet_imports.errors.ok_button')

      assert_no_selector 'dialog[open]'

      # added 0 new sample
      assert_selector 'table tbody tr', count: 3
      assert_no_selector 'table tbody tr td:nth-child(2)', text: 'my new sample'
      ### VERIFY END ###
    end

    test 'should disable select inputs if file is unselected' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(
        I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # verify initial disabled states of select inputs
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: true
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: true
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))

      # select inputs no longer disabled after file uploaded
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: false
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: false

      attach_file('spreadsheet_import[file]', Rails.root.join)
      # verify select inputs are re-disabled after file is unselected
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: true
      assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: true
      # verify blank values still exist
      assert_text I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_name_column')
      assert_text I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column')
      ### ACTIONS AND VERIFY END ###
    end

    test 'batch sample import metadata fields listing' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      # metadata sortable lists hidden
      assert_no_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv'))

      # metadata sortable lists no longer hidden
      assert_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')

      assert_text I18n.t(:'shared.samples.spreadsheet_imports.dialog.available')
      assert_text I18n.t(:'shared.samples.spreadsheet_imports.dialog.selected')

      available_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 2

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata2'

      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 3

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'description'

      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata1').click
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata2').click
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'description').click

      click_button I18n.t('common.actions.remove')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 3
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata1'
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata2'
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'description'

      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 2
      assert_no_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'description'

      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 2
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 1

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata1'
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'description'
      ### ACTIONS AND VERIFY END ###
    end

    test 'batch sample import metadata fields listing does not render if no metadata fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      # metadata sortable lists hidden
      assert_no_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))

      # confirm that file has been processed by js
      assert_field I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: false
      assert_field I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: false

      # metadata sortable lists still hidden
      assert_no_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')

      # deselect description column
      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      # metadata sortable lists renders now that description header is available
      assert_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')

      available_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'description'

      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_no_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')
      ### ACTIONS AND VERIFY END ###
    end

    test 'batch sample import with partial metadata fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')

      assert_selector 'dialog h1', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_no_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv'))
      assert_selector 'dialog div', text: I18n.t('shared.samples.spreadsheet_imports.dialog.metadata')

      available_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.spreadsheet_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 2

      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata2'

      # click on "metadata field 1" and then remove it
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata1').click
      find("ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata2').click

      click_button I18n.t('common.actions.remove')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 2
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata1'
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata2'

      select 'metadata1',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 1
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 1

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadata2'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadata1'

      click_button I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

      click_button I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'dialog[open]'

      # Confirm new samples are displayed
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 5, count: 5,
                                                                                      locale: @user.locale))
      assert_selector 'table thead tr th', count: 5

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # only metadata1 imported and not metadata2
      assert_selector 'table thead tr th', count: 8
      assert_selector 'table thead tr th:nth-child(6)', text: 'METADATA1'
      assert_no_selector 'table thead tr th', text: 'METADATA2'

      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:first-child td:nth-child(6)', text: 'c'

      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(6)', text: 'a'
    end

    test 'singular clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      find('table tbody tr:first-child th input[type="checkbox"]').click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('samples.clones.dialog.description.singular')
      ### VERIFY END ###
    end

    test 'plural clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t(
        'samples.clones.dialog.description.plural'
      ).gsub! 'COUNT_PLACEHOLDER', '3'
      ### VERIFY END ###
    end

    test 'clone dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#list_selections') do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      ### VERIFY END ###
    end

    test 'should clone samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: @user.locale))
      # verify samples 1 and 2 do not exist in project2
      assert_no_selector 'table tbody tr td:nth-child(2)', text: @sample1.name
      assert_no_selector 'table tbody tr td:nth-child(2)', text: @sample2.name

      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      find("table tbody tr th input##{dom_id(@sample1, :checkbox)}").click
      find("table tbody tr th input##{dom_id(@sample2, :checkbox)}").click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      within('#list_selections') do
        # additional asserts to help prevent select2 actions below from flaking
        assert_text @sample1.name
        assert_text @sample1.puid
        assert_text @sample2.name
        assert_text @sample2.puid
      end
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_button I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'dialog[open]'

      # samples still exist within samples table of originating project
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample2.name

      # samples now exist in project2 samples table
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 22,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample2.name
      ### VERIFY END ###
    end

    test 'dialog close button hidden while cloning samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      find("table tbody tr th input##{dom_id(@sample1, :checkbox)}").click
      find("table tbody tr th input##{dom_id(@sample2, :checkbox)}").click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      # close button available before confirming cloning
      assert_selector 'button.dialog--close'
      within('#list_selections') do
        # additional asserts to help prevent select2 actions below from flaking
        assert_text @sample1.name
        assert_text @sample1.puid
        assert_text @sample2.name
        assert_text @sample2.puid
      end
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_button I18n.t('samples.clones.dialog.submit_button')

      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      # close button hidden during cloning
      assert_no_selector 'button.dialog--close'
      ### VERIFY END ###
    end

    test 'should not clone samples with session storage cleared' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click

      click_button I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # sample listing should not be in error dialog
      assert_no_selector '#list_selections'
      # error msg
      assert_text I18n.t('samples.clones.create.no_samples_cloned_error')
      assert_text I18n.t('services.samples.clone.empty_sample_ids')
      ### VERIFY END ###
    end

    test 'should not clone some samples' do
      ### SETUP START ###
      namespace = groups(:subgroup1)
      project25 = projects(:project25)
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(namespace, project25)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      # sample30's name already exists in project25 samples table, samples1 and 2 do not
      assert_no_selector 'table tbody tr td:nth-child(2)', text: @sample1.name
      assert_no_selector 'table tbody tr td:nth-child(2)', text: @sample2.name
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample30.name

      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      within('#list_selections') do
        samples.each do |sample|
          # additional asserts to help prevent select2 actions below from flaking
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      find('input.select2-input').click
      find("li[data-value='#{project25.id}']").click
      click_button I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')

      # errors that a sample with the same name as sample30 already exists in project25
      assert_text I18n.t('samples.clones.create.error')
      assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample30.puid,
                                                                 sample_name: @sample30.name).gsub(':', '')
      click_button I18n.t('shared.samples.errors.ok_button')

      assert_no_selector 'dialog[open]'

      visit namespace_project_samples_url(namespace, project25)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      # samples 1 and 2 still successfully clone
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr td:nth-child(2)', text: @sample2.name
      ### VERIFY END ###
    end

    test 'empty state of destination project selection for sample cloning' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ####
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').fill_in with: 'invalid project name or puid'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.clones.dialog.empty_state')
      ### VERIFY END ###
    end

    test 'no available destination projects to clone samples' do
      ### SETUP START ###
      sign_in users(:jean_doe)
      visit namespace_project_samples_url(namespaces_user_namespaces(:john_doe_namespace), projects(:john_doe_project2))
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 1,
                                                                                          locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 1
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 1'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      assert_field placeholder: I18n.t('samples.clones.dialog.no_available_projects'), disabled: true
      ### VERIFY END ###
    end

    test 'updating sample selection during sample cloning' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: @user.locale))
      # verify no samples currently selected in destination project
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select 1 sample to clone
      find('table tbody tr:first-child th input[type="checkbox"]').click

      # verify 1 sample selected in originating project
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'

      # clone sample
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')
      within('#list_selections') do
        # additional asserts to help prevent select2 actions below from flaking
        assert_text @sample1.name
        assert_text @sample1.puid
      end
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_button I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1
      assert_no_text I18n.t('shared.progress_bar.in_progress')
      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'dialog[open]'

      # verify no samples selected anymore
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
      # verify destination project still has no selected samples and one additional sample
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                                      locale: @user.locale))

      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "21 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'

      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      ### VERIFY END
    end

    test 'selecting / deselecting all samples' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # no samples selected/checked
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 3
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
      # samples selected
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      # unselect single sample
      find('table tbody tr:first-child th input[name="sample_ids[]"]').click
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '2'
      # select all again
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 3
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      # deselect all
      click_button I18n.t('common.controls.deselect_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 3
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
    end

    test 'selecting / deselecting a page of samples' do
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: @user.locale))
      within('div#limit-component') do
        # set table limit to 10 to split samples table into two pages
        select '10', from: 'limit'
      end
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 10
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
      # click select page
      find('input[name="select-page"]').click
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 10
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '10'
      # unselect 1 sample
      find('table tbody tr:first-child th input[name="sample_ids[]"]').click
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '9'
      # select whole page again
      find('input[name="select-page"]').click
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 10
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 10
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '10'
      # unselect whole page
      find('input[name="select-page"]').click
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 10
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "20 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
    end

    test 'selecting samples while filtering' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 3
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: samples(:sample1).name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table tbody tr th input[name="sample_ids[]"]', count: 1
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0

      click_button I18n.t('common.controls.select_all')

      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 1
      assert_selector '[data-testid="samples-selection-summary"]', text: '1 samples'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '1'

      # remove filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: ' '
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector '[data-testid="samples-selection-summary"]',
                      text: "3 #{I18n.t('components.samples.virtualized_table_component.counts.samples').downcase}"
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '0'
    end

    test 'action links are disabled when a project does not contain any samples' do
      login_as users(:empty_doe)

      visit namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                          project_id: projects(:empty_project).path)
      assert_text I18n.t('projects.samples.index.no_associated_samples')
      assert_text I18n.t('projects.samples.index.no_samples')
      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]',
                      text: I18n.t(:'shared.samples.actions_dropdown.clone')
      assert_selector 'button[disabled]',
                      text: I18n.t(:'shared.samples.actions_dropdown.transfer')
    end

    test 'singular description within delete samples dialog' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select sample1
      find('table tbody tr:first-child th input[type="checkbox"]').click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      assert_text I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.description.singular',
                         sample_name: @sample1.name)
      ### VERIFY END ###
    end

    test 'plural description within delete samples dialog' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      assert_text I18n.t(
        'samples.deletions.destroy_multiple_confirmation_dialog.description.plural'
      ).gsub! 'COUNT_PLACEHOLDER', '3'
      ### VERIFY END ###
    end

    test 'samples listing within delete samples dialog' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      within('#list_selections') do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      ### VERIFY END ###
    end

    test 'delete multiple samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      assert_selector 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      assert_selector 'form[data-infinite-scroll-target="pageForm"]'
      sleep 1
      click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('samples.deletions.destroy.success', count: 3)

      # no remaining samples
      within 'section[role="status"]' do
        assert_text I18n.t('projects.samples.index.no_samples')
        assert_text I18n.t('projects.samples.index.no_associated_samples')
      end
    end

    test 'filter samples with advanced search' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('metadatafield1', :enter)
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
        assert_no_selector "tr[id='#{dom_id(@sample2)}']"
        # sample30 found
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search and autocomplete disabled' do
      Flipper.disable(:advanced_search_with_auto_complete)

      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("select[name$='[field]']").find("option[value='metadata.metadatafield1']").select_option
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector 'table tbody tr', count: 1
      assert_no_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      # sample30 found
      assert_selector 'table tbody tr th', text: @sample30.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using between dates' do
      ### SETUP START ###
      user = users(:metadata_doe)
      login_as user
      sample61 = samples(:sample61)
      sample62 = samples(:sample62)
      sample63 = samples(:sample63)
      project = projects(:projectMetadata)
      namespace = groups(:group_metadata)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid

      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('example_date', :enter)
          find("select[name$='[operator]']").find("option[value='>=']").select_option
          find("input[name$='[value]']").fill_in with: (DateTime.strptime(sample62.metadata['example_date'],
                                                                          '%Y-%m-%d') - 1.day).strftime('%Y-%m-%d')
        end
        click_button I18n.t(:'components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("input[role='combobox']").send_keys('example_date', :enter)
          find("select[name$='[operator]']").find("option[value='<=']").select_option
          find("input[name$='[value]']").fill_in with: (DateTime.strptime(sample62.metadata['example_date'],
                                                                          '%Y-%m-%d') + 1.day).strftime('%Y-%m-%d')
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector 'table tbody tr', count: 1
      assert_no_selector 'table tbody tr th', text: sample61.puid
      assert_no_selector 'table tbody tr th', text: sample63.puid
      # sample62 found
      assert_selector 'table tbody tr th', text: sample62.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using between floats' do
      ### SETUP START ###
      user = users(:metadata_doe)
      login_as user
      sample61 = samples(:sample61)
      sample62 = samples(:sample62)
      sample63 = samples(:sample63)
      project = projects(:projectMetadata)
      namespace = groups(:group_metadata)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('example_float', :enter)
          find("select[name$='[operator]']").find("option[value='>=']").select_option
          find("input[name$='[value]']").fill_in with: sample62.metadata['example_float'].to_f - 0.1
        end
        click_button I18n.t(:'components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("input[role='combobox']").send_keys('example_float', :enter)
          find("select[name$='[operator]']").find("option[value='<=']").select_option
          find("input[name$='[value]']").fill_in with: sample62.metadata['example_float'].to_f + 0.1
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector 'table tbody tr', count: 1
      assert_no_selector 'table tbody tr th', text: sample61.puid
      assert_no_selector 'table tbody tr th', text: sample63.puid
      # sample62 found
      assert_selector 'table tbody tr th', text: sample62.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using between integers' do
      ### SETUP START ###
      user = users(:metadata_doe)
      login_as user
      sample61 = samples(:sample61)
      sample62 = samples(:sample62)
      sample63 = samples(:sample63)
      project = projects(:projectMetadata)
      namespace = groups(:group_metadata)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('example_integer', :enter)
          find("select[name$='[operator]']").find("option[value='>=']").select_option
          find("input[name$='[value]']").fill_in with: sample62.metadata['example_integer'].to_i - 1
        end
        click_button I18n.t(:'components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("input[role='combobox']").send_keys('example_integer', :enter)
          find("select[name$='[operator]']").find("option[value='<=']").select_option
          find("input[name$='[value]']").fill_in with: sample62.metadata['example_integer'].to_i + 1
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector 'table tbody tr', count: 1
      assert_no_selector 'table tbody tr th', text: sample61.puid
      assert_no_selector 'table tbody tr th', text: sample63.puid
      # sample62 found
      assert_selector 'table tbody tr th', text: sample62.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: sample61.puid
      assert_selector 'table tbody tr th', text: sample62.puid
      assert_selector 'table tbody tr th', text: sample63.puid
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple conditions' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('metadatafield1', :enter)
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
        end
        click_button I18n.t(:'components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("input[role='combobox']").send_keys('metadatafield2', :enter)
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield2']
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector 'table tbody tr', count: 1
      assert_no_selector 'table tbody tr th', text: @sample1.puid
      assert_no_selector 'table tbody tr th', text: @sample2.puid
      # sample30 found
      assert_selector 'table tbody tr th', text: @sample30.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid

      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple conditions that fail validation' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('metadatafield1', :enter)
          find("select[name$='[operator]']").find("option[value='contains']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
        end
        click_button I18n.t(:'components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("input[role='combobox']").send_keys('metadatafield1', :enter)
          find("select[name$='[operator]']").find("option[value='contains']").select_option
          find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')
      assert_text I18n.t(:'errors.messages.taken')
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple groups' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('Sample Name', :enter)
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample1.name
        end
      end
      click_button I18n.t(:'components.advanced_search_component.add_group_button')
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2
      within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("input[role='combobox']").send_keys('Sample Name', :enter)
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: @sample2.name
        end
      end
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector 'table tbody tr', count: 2
      # sample1 & sample2 found
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_no_selector 'table tbody tr th', text: @sample30.puid

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr th', text: @sample1.puid
      assert_selector 'table tbody tr th', text: @sample2.puid
      assert_selector 'table tbody tr th', text: @sample30.puid
      ### actions and VERIFY END ###
    end

    test 'can update metadata value that is not from an analysis' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'table thead tr th', count: 5

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ## SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[data-editable="true"]'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return) # Activate edit mode with Enter

        find('td:nth-child(7)').send_keys('value2')
        find('td:nth-child(7)').native.send_keys(:return)
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector 'td:nth-child(7)', text: 'value2'
      end
      assert_text I18n.t('samples.editable_cell.update_success')

      assert_no_selector 'dialog[open]'
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')

      # Regression: ensure the same cell remains editable after the Turbo Stream update
      within('table tbody tr:first-child') do
        assert_selector 'td:nth-child(7)[aria-colindex="7"]'
        assert_selector 'td:nth-child(7)[data-editable="true"]', text: 'value2'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return)

        find('td:nth-child(7)').send_keys('value3')
        find('td:nth-child(7)').native.send_keys(:return)

        assert_selector 'td:nth-child(7)', text: 'value3'
      end
      ### VERIFY END ###
    end

    test 'should not update metadata value that is from an analysis' do
      ### SETUP START ###
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      visit namespace_project_samples_url(subgroup12aa, project31)
      assert_selector 'table thead tr th', count: 5

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      click_on I18n.t('projects.samples.show.table_header.last_updated')
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end

      ### SETUP END ###

      ### VERIFY START ###
      assert_no_selector 'table tbody tr:nth-child(1) td:nth-child(6)[contenteditable="true"]'
      ### VERIFY END ###
    end

    test 'project analysts should not be able to edit samples' do
      ### SETUP START ###
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'table thead tr th', count: 5

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample2.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### SETUP END ###

      ### VERIFY START ###
      assert_no_selector "table tbody tr:first-child td:nth-child(7) form[method='get']"
      ### VERIFY END ###
    end

    test 'shows confirmation dialog when editing metadata field with changes' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table thead tr th', count: 5

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[data-editable="true"]'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return) # Activate edit mode with Enter

        find('td:nth-child(7)').send_keys('New Value')
      end
      find('body').click

      assert_selector 'dialog[open]'
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')

      click_button I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_no_selector 'dialog[open]'
      within('table tbody tr:first-child') do
        assert_selector 'td:nth-child(7)', text: 'New Value'
      end
      ### VERIFY END ###
    end

    test 'shows confirmation dialog can be cancelled resetting the value' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'table thead tr th', count: 5

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[data-editable="true"]'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return) # Activate edit mode with Enter

        find('td:nth-child(7)').send_keys('New Value')
      end
      find('body').click

      assert_selector 'dialog[open]'
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')

      click_button I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_no_selector 'dialog[open]'
      within('table tbody tr:first-child') do
        assert_no_selector 'td:nth-child(7)', text: 'New Value'
      end
      ### VERIFY END ###
    end

    test 'editing metadata value with leading/trailing whitespaces should not update metadata' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector 'table thead tr th', count: 5

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ## SETUP END ###

      ### ACTIONS AND VERIFY START ###
      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      assert_selector 'table tbody tr:first-child td:nth-child(7)[contenteditable="true"]'

      metadata_cell.send_keys('value 2')
      metadata_cell.send_keys(:return)
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'value 2'
      assert_text I18n.t('samples.editable_cell.update_success')
      ### ACTIONS AND VERIFY END ###

      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      # When edit mode is activated, text is selected, so typing replaces it
      # Type the same value with trailing whitespace - should not update after trim
      metadata_cell.send_keys('value 2     ')
      metadata_cell.send_keys(:return)
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'value 2'
      assert_no_text I18n.t('samples.editable_cell.update_success')

      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      metadata_cell.send_keys('     value 2')
      metadata_cell.send_keys(:return)
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'value 2'
      assert_no_text I18n.t('samples.editable_cell.update_success')

      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      metadata_cell.send_keys('     value 2     ')
      metadata_cell.send_keys(:return)
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'value 2'
      assert_no_text I18n.t('samples.editable_cell.update_success')

      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      metadata_cell.send_keys('value      2')
      metadata_cell.send_keys(:return)
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'value 2'
      assert_no_text I18n.t('samples.editable_cell.update_success')
    end

    test 'confirmation dialog does not prompt for edit metadata with leading/trailing whitespaces' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'table thead tr th', count: 5

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 7

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      metadata_cell = find('table tbody tr:first-child td:nth-child(7)')
      metadata_cell.click
      metadata_cell.send_keys(:return) # Activate edit mode
      assert_selector 'table tbody tr:first-child td:nth-child(7)[contenteditable="true"]'
      metadata_cell.send_keys('New Value')
      find('body').click

      assert_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_selector 'dialog button', text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')

      click_button I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'New Value'

      metadata_cell.click
      metadata_cell.send_keys([:control, 'a'], :backspace, 'New Value         ')
      find('body').click
      assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'New Value'

      metadata_cell.click
      metadata_cell.send_keys([:control, 'a'], :backspace, '            New Value')
      find('body').click
      assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'New Value'

      metadata_cell.click
      metadata_cell.send_keys([:control, 'a'], :backspace, '     New Value      ')
      find('body').click
      assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'New Value'

      metadata_cell.click
      metadata_cell.send_keys([:control, 'a'], :backspace, 'New     Value')
      find('body').click
      assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
      assert_selector 'table tbody tr:first-child td:nth-child(7)', text: 'New Value'
    end

    test 'linelist export test' do
      metadata_template = metadata_templates(:project1_metadata_template0)
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      # Assert that the Export button is disabled when no samples are selected
      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]',
                      text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 3
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector '[data-testid="samples-selection-summary"]', text: ' 3'
      assert_selector '[data-testid="samples-selection-summary"] [data-selection-target="selected"]', text: '3'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

      assert_selector 'dialog h1', text: I18n.t(:'data_exports.new_linelist_export_dialog.title')

      available_label_id = find('p', text: I18n.t(:'data_exports.new_linelist_export_dialog.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'shared.samples.metadata.file_imports.dialog.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: @project.namespace.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      assert_no_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      select metadata_template.name, from: I18n.t('data_exports.new.template_select_label')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector "ul[aria-labelledby='#{available_label_id}'] li",
                      count: @project.namespace.metadata_fields.count - metadata_template.fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: metadata_template.fields.count

      assert_no_selector "ul[aria-labelledby='#{available_label_id}'] li", text: 'metadatafield1'
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: 'metadatafield1'
      ### VERIFY END ###
    end

    test 'pagy overflow redirects to first page' do
      project = projects(:project38)
      sample = samples(:bulk_sample19)

      visit namespace_project_samples_url(project.namespace.parent, project)

      assert_selector 'table tbody tr', count: 20

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')

      # verifies navigation to page
      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      # samples table
      assert_selector 'table tbody tr', count: 20

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: sample.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # Search for PUID
      # rows
      assert_selector 'table tbody tr', count: 11

      assert_selector "table tbody tr[id='#{dom_id(sample)}'] th:first-child", text: sample.puid
      assert_selector "table tbody tr[id='#{dom_id(sample)}'] td:nth-child(2)", text: sample.name
    end

    def long_filter_text
      text = (1..500).map { |n| "sample#{n}" }.join(', ')
      "#{text}, #{@sample1.name}" # Need to comma to force the tag to be created
    end

    test 'local_time localization with language toggle' do
      freeze_time
      visit namespace_project_samples_url(@namespace, @project)

      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')

      # samples table
      # headers
      assert_selector 'table thead tr:first-child th:nth-child(4)',
                      text: I18n.t('components.samples.virtualized_table_component.updated_at').upcase
      assert_selector 'table thead tr:first-child th:nth-child(5)',
                      text: I18n.t('components.samples.virtualized_table_component.attachments_updated_at').upcase
      # values with time_ago
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(4)", text: '3 hours ago'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(5)", text: '2 hours ago'

      # change language
      find('#language-selection-dd-trigger').click
      within find('#language-selection-dd-menu') do
        click_button I18n.t(:'locales.fr', locale: :fr)
      end

      # verify language change without refresh
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(4)", text: 'il y a 3 heures'
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(5)", text: 'il y a 2 heures'
    end
  end
end
