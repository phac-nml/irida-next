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
      @sample30 = samples(:sample30)
      @sample32 = samples(:sample32)
      @project = projects(:project1)
      @project2 = projects(:project2)
      @project29 = projects(:project29)
      @namespace = groups(:group_one)
      @subgroup12a = groups(:subgroup_twelve_a)

      Sample.reindex
      Searchkick.enable_callbacks
    end

    teardown do
      Searchkick.disable_callbacks
    end

    test 'samples index table' do
      freeze_time
      visit namespace_project_samples_url(@namespace, @project)

      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')

      # samples table
      within('#samples-table table') do
        # headers
        within('thead tr:first-child') do
          assert_selector 'th:first-child', text: I18n.t('samples.table_component.puid').upcase
          assert_selector 'th:nth-child(2)', text: I18n.t('samples.table_component.name').upcase
          assert_selector 'th:nth-child(3)', text: I18n.t('samples.table_component.created_at').upcase
          assert_selector 'th:nth-child(4)', text: I18n.t('samples.table_component.updated_at').upcase
          assert_selector 'th:nth-child(5)', text: I18n.t('samples.table_component.attachments_updated_at').upcase
          assert_selector 'th:last-child', text: I18n.t('samples.table_component.action').upcase
        end
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 3
          # row contents
          within("tr[id='#{@sample1.id}']") do
            assert_selector 'th:first-child', text: @sample1.puid
            assert_selector 'td:nth-child(2)', text: @sample1.name
            assert_selector 'td:nth-child(3)', text: I18n.l(@sample1.created_at.localtime, format: :full_date)
            assert_selector 'td:nth-child(4)', text: '3 hours ago'
            assert_selector 'td:nth-child(5)', text: '2 hours ago'
            # actions tested by role in separate test
          end
        end
      end
    end

    test 'edit and delete row actions render for user with Owner role' do
      visit namespace_project_samples_url(@namespace, @project)

      within("tr[id='#{@sample1.id}'] td:last-child") do
        assert_selector 'a', text: I18n.t('projects.samples.index.edit_button')
        assert_selector 'a', text: I18n.t('projects.samples.index.remove_button')
      end
    end

    test 'edit row action render for user with Maintainer role' do
      login_as users(:joan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      within("tr[id='#{@sample1.id}'] td:last-child") do
        assert_selector 'a', text: I18n.t('projects.samples.index.edit_button')
        assert_no_selector 'a', text: I18n.t('projects.samples.index.remove_button')
      end
    end

    test 'no row actions for user with role < Maintainer' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      within('#samples-table table thead tr:first-child') do
        # attachments_updated_at is the last column, action column does not exist
        assert_selector 'th:last-child', text: I18n.t('samples.table_component.attachments_updated_at').upcase
        assert_no_selector 'th:last-child', text: I18n.t('samples.table_component.action').upcase
      end
      within("tr[id='#{@sample1.id}'] td:last-child") do
        assert_no_selector 'a', text: I18n.t('projects.samples.index.edit_button')
        assert_no_selector 'a', text: I18n.t('projects.samples.index.remove_button')
      end
    end

    test 'User with role >= Maintainer sees select and deselect buttons for samples table' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'form#select-all-form'
      assert_selector 'form#deselect-all-form'
    end

    test 'User with role < Maintainer does not see select and deselect buttons for samples table' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'form#select-all-form'
      assert_no_selector 'form#deselect-all-form'
    end

    test 'User with role >= Maintainer sees sample table checkboxes' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'input#select-page'
      assert_selector "input#sample_#{@sample1.id}"
    end

    test 'User with role < Maintainer does not see sample table checkboxes' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'input#select-page'
      assert_no_selector "input#sample_#{@sample1.id}"
    end

    test 'User with role >= Analyst sees workflow execution link' do
      login_as users(:james_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'span[class="sr-only"]', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role < Analyst does not see workflow execution link' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'span[class="sr-only"]', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role >= Analyst sees create export button' do
      login_as users(:james_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
    end

    test 'User with role < Analyst does not see create export button' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
    end

    test 'User with role >= Maintainer sees import metadata button' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.import_metadata_button')
    end

    test 'User with role < Maintainer does not see import metadata button' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'a', text: I18n.t('projects.samples.index.import_metadata_button')
    end

    test 'User with role >= Maintainer sees new sample button' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button')
    end

    test 'User with role < Maintainer does not see new sample button' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'a', text: I18n.t('projects.samples.index.new_button')
    end

    test 'User with role >= Maintainer sees delete samples button' do
      visit namespace_project_samples_url(@namespace, @project)

      assert_selector 'a', text: I18n.t('projects.samples.index.delete_samples_button')
    end

    test 'User with role < Maintainer does not see delete samples button' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)

      assert_no_selector 'a', text: I18n.t('projects.samples.index.delete_samples_button')
    end

    test 'cannot access project samples' do
      login_as users(:user_no_access)

      visit namespace_project_samples_url(@namespace, @project)

      assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
    end

    test 'create sample' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within('#samples-table table tbody') do
        # sample does not currently exist
        assert_no_text 'New Name'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # launch dialog
      click_on I18n.t('projects.samples.index.new_button')

      # fill new sample fields
      fill_in I18n.t('activerecord.attributes.sample.description'), with: 'A sample description'
      fill_in I18n.t('activerecord.attributes.sample.name'), with: 'New Name'
      click_on I18n.t('projects.samples.new.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('projects.samples.create.success')
      # verify redirect to sample show page after successful sample creation
      assert_selector 'h1', text: 'New Name'
      assert_selector 'p', text: 'A sample description'
      # verify sample exists in samples table
      visit namespace_project_samples_url(@namespace, @project)
      within('#samples-table table tbody') do
        assert_text 'New Name'
      end
      ### VERIFY END ###
    end

    test 'edit sample' do
      ### SETUP START ###
      visit namespace_project_sample_url(@namespace, @project, @sample1)
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
      click_on I18n.t('projects.samples.edit.submit_button')
      ### ACTIONS END ###

      ### results start ###
      # success flash msg
      assert_text I18n.t('projects.samples.update.success')

      # verify redirect to sample show page and updated sample state
      assert_selector 'h1', text: 'New Sample Name'
      assert_text 'A new description'
      ### results end ###
    end

    test 'destroy sample from sample show page' do
      ### SETUP START ###
      # nav to samples index and verify sample exists within table
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector "#samples-table table tbody tr[id='#{@sample1.id}']"
      assert_selector '#samples-table table tbody tr', count: 3

      # nav to sample show
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      ### SETUP END ###

      ### ACTIONS START ##
      # remove sample
      click_link I18n.t(:'projects.samples.index.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                       project_name: @project.namespace.human_name)
      # redirected to samples index
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      # deleted sample row no longer exists
      assert_no_selector "#samples-table table tbody tr[id='#{@sample1.id}']"
      # remaining samples still appear on table
      assert_selector '#samples-table table tbody tr', count: 2
      ### VERIFY END ###
    end

    test 'should destroy Sample from samples table' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within("tr[id='#{@sample1.id}']") do
        # click remove action
        click_link I18n.t('projects.samples.index.remove_button')
      end

      # confirm destroy action
      within('#dialog') do
        assert_text I18n.t('projects.samples.deletions.new_deletion_dialog.description', sample_name: @sample1.name)
        click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                       project_name: @project.namespace.human_name)
      # sample no longer exists
      assert_no_selector "tr[id='#{@sample1.id}']"
      # still on samples index page
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      # remaining samples still in table
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                           locale: @user.locale))
      ### VERIFY END ###
    end

    test 'transfer dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.transfer_button')
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

    test 'transfer dialog with plural description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.transfer_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                         '3')
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with singular description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_link I18n.t('projects.samples.index.transfer_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'transfer samples' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      # show destination project has 20 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      # originating project has 3 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.transfer_button')
      within('#dialog') do
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        # select destination project
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('projects.samples.transfers.create.success')
      # originating project no longer has samples
      assert_text I18n.t('projects.samples.index.no_samples')

      # destination project received transferred samples
      visit namespace_project_samples_url(@namespace, @project2)
      within '#samples-table table tbody' do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 23,
                                                                           locale: @user.locale))
      ### VERIFY END ###
    end

    test 'should not transfer samples with session storage cleared' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      # launch transfer dialog
      click_link I18n.t('projects.samples.index.transfer_button')
      within('#dialog') do
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # samples listing should no longer appear in dialog
        assert_no_selector '#list_selections'
        # error msg displayed in dialog
        assert_text I18n.t('projects.samples.transfers.create.no_samples_transferred_error')
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                           locale: @user.locale))
      # 3 samples in originating project
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.transfer_button')
      within('#dialog') do
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{project25.id}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # error messages in dialog
        assert_text I18n.t('projects.samples.transfers.create.error')
        # colon is removed from translation in UI
        assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: @sample30.puid,
                                                                      sample_name: @sample30.name).gsub(':', '')
      end

      # verify sample1 and 2 transferred, sample 30 did not
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1, locale: @user.locale))
      assert_no_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_selector "tr[id='#{@sample30.id}']"

      # destination project
      visit namespace_project_samples_url(namespace, project25)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                           locale: @user.locale))
      assert_selector "tr[id='#{@sample1.id}']"
      assert_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"
      ### VERIFY END ###
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      ### SETUP START ###
      login_as users(:user28)
      namespace = groups(:group_hotel)
      project = projects(:projectHotel)
      visit namespace_project_samples_url(namespace, project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.transfer_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # no available destination projects
        assert_selector "input[placeholder='#{I18n.t('projects.samples.transfers.dialog.no_available_projects')}']"
      end
      ### VERIFY END ###
    end

    test 'updating sample selection during transfer samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)

      # verify no samples currently selected in destination project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      # select 1 sample to transfer
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end

      # verify 1 sample selected in originating project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      # transfer sample
      click_link I18n.t('projects.samples.index.transfer_button')
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
        end
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify no samples selected anymore
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 2"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      # verify destination project still has no selected samples and one additional sample
      visit namespace_project_samples_url(@namespace, @project2)
      assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      ### VERIFY END
    end

    test 'empty state of transfer sample project selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')

      # launch dialog
      click_link I18n.t('projects.samples.index.transfer_button')
      within('#dialog') do
        # fill destination input
        find('input#select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('projects.samples.transfers.dialog.empty_state')
        ### VERIFY END ###
      end
    end

    test 'limit persists through filter and sort actions' do
      # tests limit change and that it persists through other actions (filter)
      ### SETUP START ###
      sample3 = samples(:sample3)
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### actions and VERIFY START ###
      within('div#limit-component') do
        # set table limit to 10
        find('button').click
        click_link '10'
      end

      # verify limit is set to 10
      assert_selector 'div#limit-component button div span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 20,
                                                                           locale: @user.locale))
      # verify table consists of 10 samples per page
      assert_selector '#samples-table table tbody tr', count: 10

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: sample3.puid
      find('input.t-search-component').native.send_keys(:return)

      # verify limit is still 10
      assert_selector 'div#limit-component button div span', text: '10'

      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      # verify limit is still 10
      assert_selector 'div#limit-component button div span', text: '10'
      ### actions and VERIFY END ###
    end

    test 'can sort samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTION and VERIFY START ###
      within('tbody tr:first-child th') do
        assert_text @sample1.puid
      end
      # sort by name
      click_on I18n.t('samples.table_component.name')

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample30.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample30.name
      end

      # change name sort direction
      click_on I18n.t('samples.table_component.name')

      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      within('#samples-table table tbody') do
        assert_selector 'tr:first-child th', text: @sample30.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample30.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
        assert_selector 'tr:last-child th', text: @sample1.puid
        assert_selector 'tr:last-child td:nth-child(2)', text: @sample1.name
      end
      ### ACTION and VERIFY END ###
    end

    test 'sort persists through limit and filter' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### actions and VERIFY START ###
      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      # set limit
      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      # verify sort is still applied
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      # verify sort is still applied
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      ### actions and VERIFY END ###
    end

    test 'filter by name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector "tr[id='#{@sample1.id}']"
      assert_selector "tr[id='#{@sample2.id}']"
      assert_selector "tr[id='#{@sample30.id}']"
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample1 exists within table
      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"
      ### VERIFY END ###
    end

    test 'filter by puid' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector "tr[id='#{@sample1.id}']"
      assert_selector "tr[id='#{@sample2.id}']"
      assert_selector "tr[id='#{@sample30.id}']"
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample2.puid
      find('input.t-search-component').native.send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample2 exists within table
      assert_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"
      ### VERIFY END ###
    end

    test 'filter highlighting for sample name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: 'sample'
      find('input.t-search-component').native.send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify table still contains all samples
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # checks highlighting
      assert_selector 'mark', text: 'Sample', count: 3
      ### VERIFY END ###
    end

    test 'filter highlighting for sample puid' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify table only contains sample1
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      # checks highlighting
      assert_selector 'mark', text: @sample1.puid
      ### VERIFY END ###
    end

    test 'filter persists through sort and limit actions' do
      ### SETUP START ###
      filter_text = @sample1.name
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector "tr[id='#{@sample1.id}']"
      assert_selector "tr[id='#{@sample2.id}']"
      assert_selector "tr[id='#{@sample30.id}']"
      ### SETUP END ###

      ### ACTIONS and VERIFY START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
      find('input.t-search-component').native.send_keys(:return)

      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"

      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      # verify table still only contains sample1
      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"

      # verify filter text is still in filter input
      assert_selector %(input.t-search-component) do |input|
        assert_equal filter_text, input['value']
      end

      # set limit
      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      # verify table still only contains sample1
      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"

      # verify filter text is still in filter input
      assert_selector %(input.t-search-component) do |input|
        assert_equal filter_text, input['value']
      end
      ### VERIFY END ###
    end

    test 'filter persists through page refresh' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      filter_text = @sample1.name
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
      find('input.t-search-component').native.send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"

      # refresh
      visit namespace_project_samples_url(@namespace, @project)

      # verify filter is still in input field
      assert_selector %(input.t-search-component) do |input|
        assert_equal filter_text, input['value']
      end
      assert_selector "tr[id='#{@sample1.id}']"
      assert_no_selector "tr[id='#{@sample2.id}']"
      assert_no_selector "tr[id='#{@sample30.id}']"
      ### VERIFY END ###
    end

    test 'sort persists through page refresh' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      assert_selector '#samples-table table tbody th:first-child', text: @sample1.puid
      # change sort order from default sorting
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### ACTIONS END ###

      ### VERIFY START ###
      # refresh
      visit namespace_project_samples_url(@namespace, @project)

      # verify sort is still enabled
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
      # verify table ordering is still in sorted state
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'should import metadata via csv' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          # metadatafield1 and 2 already exist, 3 does not and will be added by the import
          assert_text 'METADATAFIELD1'
          assert_text 'METADATAFIELD2'
          assert_no_text 'METADATAFIELD3'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # success msg
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      # metadatafield3 added to header
      assert_selector '#samples-table table thead tr th', count: 9
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # sample 1 and 2 metadata is updated
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '20'
          assert_selector 'td:nth-child(8)', text: '30'
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: '15'
          assert_selector 'td:nth-child(7)', text: '25'
          assert_selector 'td:nth-child(8)', text: '35'
        end
      end
      ### VERIFY END ###
    end

    test 'should import metadata via xls' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          # metadatafield 3 and 4 will be added by import
          assert_no_text 'METADATAFIELD3'
          assert_no_text 'METADATAFIELD4'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xls')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      # metadatafield3 and 4 added to header
      assert_selector '#samples-table table thead tr th', count: 10
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_text 'METADATAFIELD4'
        end
        # new metadata values for sample 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '2024-01-04'
          assert_selector 'td:nth-child(8)', text: 'true'
          assert_selector 'td:nth-child(9)', text: 'A Test'
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: '15'
          assert_selector 'td:nth-child(7)', text: '2024-12-31'
          assert_selector 'td:nth-child(8)', text: 'false'
          assert_selector 'td:nth-child(9)', text: 'Another Test'
        end
      end
      ### VERIFY END ###
    end

    test 'should import metadata via xlsx' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          # metadatafield 3 and 4 will be added by import
          assert_no_text 'METADATAFIELD3'
          assert_no_text 'METADATAFIELD4'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      # metadatafield3 and 4 added to header
      assert_selector '#samples-table table thead tr th', count: 10
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_text 'METADATAFIELD4'
        end
        # new metadata values for sample 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '2024-01-04'
          assert_selector 'td:nth-child(8)', text: 'true'
          assert_selector 'td:nth-child(9)', text: 'A Test'
        end
        within("tr[id='#{@sample2.id}']") do
          assert_selector 'td:nth-child(6)', text: '15'
          assert_selector 'td:nth-child(7)', text: '2024-12-31'
          assert_selector 'td:nth-child(8)', text: 'false'
          assert_selector 'td:nth-child(9)', text: 'Another Test'
        end
      end
      ### VERIFY END ###
    end

    test 'should not import metadata via invalid file type' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # error msg
        assert_text I18n.t('services.samples.metadata.import_file.invalid_file_extension')
      end
      ### VERIFY END ###
    end

    test 'should import metadata with ignore empty values' do
      # enabled ignore empty values will leave sample metadata values unchanged
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      within("tr[id='#{@sample32.id}']") do
        # value for metadatafield1, which is blank on the csv to import and will be left unchanged after import
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        # enable ignore empty values
        find('input#file_import_ignore_empty_values').click
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      within("tr[id='#{@sample32.id}']") do
        # unchanged value
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### VERIFY END ###
    end

    test 'should import metadata without ignore empty values' do
      # disabled ignore empty values will delete any metadata values that are empty on the import
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      within("tr[id='#{@sample32.id}']") do
        # value for metadatafield1, which is blank on the csv to import and will be deleted by the import
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        # leave ignore empty values disabled
        assert_not find('input#file_import_ignore_empty_values').checked?
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      within("tr[id='#{@sample32.id}']") do
        # value is deleted for metadatafield1
        assert_selector 'td:nth-child(6)', text: ''
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with duplicate header errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # error msg
        assert_text I18n.t('services.samples.metadata.import_file.duplicate_column_names')
        ### VERIFY END ###
      end
    end

    test 'should not import metadata with missing metadata row errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # error msg
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_row')
        ### VERIFY END ###
      end
    end

    test 'should not import metadata with missing metadata column errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # error msg
        assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_column')
        ### VERIFY END ###
      end
    end

    test 'should partially import metadata with missing sample errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          # metadatafield1 and 2 already exist, 3 does not and will be added by the import
          assert_text 'METADATAFIELD1'
          assert_text 'METADATAFIELD2'
          assert_no_text 'METADATAFIELD3'
        end
        # sample 1 has no current value for metadatafield 1 and 2
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # sample 3 does not exist in current project
        assert_text I18n.t('services.samples.metadata.import_file.sample_not_found_within_project',
                           sample_puid: 'Project 2 Sample 3')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end

      # metadata still imported
      assert_selector '#samples-table table thead tr th', count: 9
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # sample 1 still imported even though sample3 (from import) does not exist
        within("tr[id='#{@sample1.id}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '20'
          assert_selector 'td:nth-child(8)', text: '30'
        end
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with analysis values' do
      ### SETUP START ###
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      sample34 = samples(:sample34)
      visit namespace_project_samples_url(subgroup12aa, project31)
      # toggle metadata on for samples table
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      # metadata that does not overwriting analysis values will still be added
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table thead') do
        assert_no_text 'METADATAFIELD3'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t('projects.samples.index.import_metadata_button')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                           sample_name: sample34.name, metadata_fields: 'metadatafield1')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end
      # metadatafield3 still added
      assert_selector '#samples-table table thead tr th', count: 9
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # new metadata value
        within("tr[id='#{sample34.id}']") do
          assert_selector 'td:nth-child(8)', text: '20'
        end
        ### VERIFY END ###
      end
    end

    test 'singular clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_link I18n.t('projects.samples.index.clone_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('projects.samples.clones.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'plural clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.clone_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t(
          'projects.samples.clones.dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
      end
      ### VERIFY END ###
    end

    test 'clone dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.clone_button')
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
      # verify samples 1 and 2 do not exist in project2
      within('#samples-table table tbody') do
        assert_no_text @sample1.name
        assert_no_text @sample2.name
      end

      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      within '#samples-table table tbody' do
        find("input#sample_#{@sample1.id}").click
        find("input#sample_#{@sample2.id}").click
      end
      click_link I18n.t('projects.samples.index.clone_button')
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.puid
        end
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('projects.samples.clones.create.success')
      # samples still exist within samples table of originating project
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end

      # samples now exist in project2 samples table
      visit namespace_project_samples_url(@namespace, @project2)
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end
      ### VERIFY END ###
    end

    test 'should not clone samples with session storage cleared' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      click_link I18n.t('projects.samples.index.clone_button')
      within('#dialog') do
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
        ### ACTIONS END ###

        ### VERIFY START ###
        # sample listing should not be in error dialog
        assert_no_selector '#list_selections'
        # error msg
        assert_text I18n.t('projects.samples.clones.create.no_samples_cloned_error')
        assert_text I18n.t('services.samples.clone.empty_sample_ids')
        ### VERIFY END ###
      end
    end

    test 'should not clone some samples' do
      ### SETUP START ###
      namespace = groups(:subgroup1)
      project25 = projects(:project25)
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(namespace, project25)
      # sample30's name already exists in project25 samples table, samples1 and 2 do not
      within('#samples-table table tbody') do
        assert_no_text @sample1.name
        assert_no_text @sample2.name
        assert_text @sample30.name
      end
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.clone_button')
      within('#dialog') do
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{project25.id}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')

        ### ACTIONS END ###

        ### VERIFY START ###
        # errors that a sample with the same name as sample30 already exists in project25
        assert_text I18n.t('projects.samples.clones.create.error')
        assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample30.puid,
                                                                   sample_name: @sample30.name).gsub(':', '')
        click_on I18n.t('projects.samples.shared.errors.ok_button')
      end

      visit namespace_project_samples_url(namespace, project25)
      # samples 1 and 2 still successfully clone
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end
      ### VERIFY END ###
    end

    test 'empty state of destination project selection for sample cloning' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ####
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.clone_button')
      within('#dialog') do
        find('input#select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('projects.samples.clones.dialog.empty_state')
        ### VERIFY END ###
      end
    end

    test 'no available destination projects to clone samples' do
      ### SETUP START ###
      sign_in users(:jean_doe)
      visit namespace_project_samples_url(namespaces_user_namespaces(:john_doe_namespace), projects(:john_doe_project2))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.clone_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert "input[placeholder='#{I18n.t('projects.samples.clones.dialog.no_available_projects')}']"
      end
      ### VERIFY END ###
    end

    test 'updating sample selection during sample cloning' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)
      # verify no samples currently selected in destination project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      # select 1 sample to clone
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end

      # verify 1 sample selected in originating project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      # clone sample
      click_link I18n.t('projects.samples.index.clone_button')
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
        end
        find('input#select2-input').click
        find("button[data-viral--select2-value-param='#{@project2.id}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('projects.samples.clones.create.success')
      # verify no samples selected anymore
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      # verify destination project still has no selected samples and one additional sample
      visit namespace_project_samples_url(@namespace, @project2)

      assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      ### VERIFY END
    end

    test 'selecting / deselecting all samples' do
      visit namespace_project_samples_url(@namespace, @project)
      # no samples selected/checked
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      # samples selected
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      # unselect single sample
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '2'
      end
      # select all again
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      # deselect all
      click_button I18n.t(:'projects.samples.index.deselect_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
    end

    test 'selecting / deselecting a page of samples' do
      visit namespace_project_samples_url(@namespace, @project2)
      within('div#limit-component') do
        # set table limit to 10 to split samples table into two pages
        find('button').click
        click_link '10'
      end
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 10
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      # click select page
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 10
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '10'
      end
      # unselect 1 sample
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '9'
      end
      # select whole page again
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 10
        assert_selector 'input[name="sample_ids[]"]:checked', count: 10
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '10'
      end
      # unselect whole page
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 10
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
    end

    test 'selecting samples while filtering' do
      visit namespace_project_samples_url(@namespace, @project)
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      # apply filter
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

      # remove filter
      fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: ' '
      find('input.t-search-component').native.send_keys(:return)

      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
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

    test 'singular description within delete samples dialog' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      within('tbody tr:first-child') do
        # select sample1
        all('input[type="checkbox"]')[0].click
      end
      click_link I18n.t('projects.samples.index.delete_samples_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.description.singular',
                           sample_name: @sample1.name)
      end
      ### VERIFY END ###
    end

    test 'plural description within delete samples dialog' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.delete_samples_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t(
          'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
      end
      ### VERIFY END ###
    end

    test 'samples listing within delete samples dialog' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.delete_samples_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog #list_selections') do
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
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_link I18n.t('projects.samples.index.delete_samples_button')
      within('#dialog') do
        click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

      # no remaining samples
      within 'div[role="alert"]' do
        assert_text I18n.t('projects.samples.index.no_samples')
        assert_text I18n.t('projects.samples.index.no_associated_samples')
      end
    end

    test 'delete single sample with remove link while all samples selected followed by multiple deletion' do
      # tests that localstorage does not contain a selected sample after it's destroyed
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector "tr[id='#{@sample1.id}']"
      assert_selector "tr[id='#{@sample2.id}']"
      assert_selector "tr[id='#{@sample30.id}']"
      ### SETUP END ###

      ### ACTIONS START ###
      # select all samples
      click_button I18n.t(:'projects.samples.index.select_all_button')

      # destroy sample1 with remove action link
      within '#samples-table table tbody tr:first-child' do
        click_link I18n.t('projects.samples.index.remove_button')
      end

      within '#dialog' do
        click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
      end

      # sample 1 no longer exists and both remaining samples are still selected
      within '#samples-table table tbody' do
        assert_no_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
        assert_selector 'input[name="sample_ids[]"]:checked', count: 2
      end

      # click delete samples button
      click_link I18n.t('projects.samples.index.delete_samples_button')
      within('#dialog') do
        # verify sample2 and 30 are still in localstorage, and sample1 is not
        assert_text I18n.t(
          'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '2'
        within('#list_selections') do
          assert_text @sample2.name
          assert_text @sample30.name
          assert_no_text @sample1.name
        end
        click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

      within 'div[role="alert"]' do
        assert_text I18n.t('projects.samples.index.no_samples')
        assert_text I18n.t('projects.samples.index.no_associated_samples')
      end
      ### VERIFY END ###
    end

    test 'filtering samples by list of sample puids' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        # add sample1 and 2 puids
        fill_in I18n.t(:'components.list_filter.description'), with: "#{@sample1.puid}, #{@sample2.puid}"
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        # sample30 filtered out
        assert_no_selector "tr[id='#{@sample30.id}']"
      end
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        # clear filter
        click_button I18n.t(:'components.list_filter.clear')
        click_button I18n.t(:'components.list_filter.apply')
      end
      within '#samples-table table tbody' do
        # sample30 no longer filtered
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
      end
      ### actions and VERIFY END ###
    end

    test 'filtering samples by list of sample names' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        # add sample1 and 2 names
        fill_in I18n.t(:'components.list_filter.description'), with: "#{@sample1.name}, #{@sample2.name}"
        click_button I18n.t(:'components.list_filter.apply')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        # sample30 filtered out
        assert_no_selector "tr[id='#{@sample30.id}']"
      end
      ### VERIFY END ###
    end

    test 'can filter by large list of sample names or ids' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'components.list_filter.title')
      within '#list-filter-dialog' do |dialog|
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        fill_in I18n.t(:'components.list_filter.description'), with: long_filter_text
        assert_selector 'span.label', count: 500
        dialog.scroll_to(dialog.find('button', text: I18n.t(:'components.list_filter.apply')), align: :bottom)
        click_button I18n.t(:'components.list_filter.apply')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"
      end
      ### VERIFY END ###
    end

    def long_filter_text
      text = (1..500).map { |n| "sample#{n}" }.join(', ')
      "#{text}, #{@sample1.name}" # Need to comma to force the tag to be created
    end
  end
end
