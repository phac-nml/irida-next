# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      Flipper.enable(:metadata_import_field_selection)
      Flipper.enable(:batch_sample_spreadsheet_import)

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

      Flipper.enable(:progress_bars)
      Flipper.enable(:group_samples_clone)
    end

    test 'samples index table' do
      freeze_time
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
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
        end
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 3
          # row contents
          within("tr[id='#{dom_id(@sample1)}']") do
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

    test 'User with role >= Analyst sees select and deselect buttons for samples table' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      assert_selector 'form#select-all-form'
      assert_selector 'form#deselect-all-form'
    end

    test 'User with role < Analyst does not see select and deselect buttons for samples table' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      assert_no_selector 'form#select-all-form'
      assert_no_selector 'form#deselect-all-form'
    end

    test 'User with role >= Analyst sees sample table checkboxes' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      assert_selector 'input#select-page'
      assert_selector "input##{dom_id(@sample1, :checkbox)}"
    end

    test 'User with role < Analyst does not see sample table checkboxes' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      assert_no_selector 'input#select-page'
      assert_no_selector "input##{dom_id(@sample1, :checkbox)}"
    end

    test 'User with role >= Analyst sees workflow execution link' do
      user = users(:james_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))

      assert_selector 'span',
                      text: I18n.t('projects.samples.index.workflows.button_sr', locale: user.locale)
    end

    test 'User with role < Analyst does not see workflow execution link' do
      user = users(:ryan_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))

      assert_no_selector 'span', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role >= Analyst sees sample actions dropdown' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role < Analyst does not see sample actions dropdown' do
      login_as users(:ryan_doe)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_no_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role >= Analyst sees create export button' do
      user = users(:james_doe)
      login_as user
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))

      assert_no_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
    end

    test 'User with role >= Maintainer sees import metadata button' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        # sample does not currently exist
        assert_no_text 'New Name'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.new_sample')

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
      assert_selector 'span', text: 'A sample description'
      # verify sample exists in samples table
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_text 'New Name'
      end
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      # select all samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector 'tr', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end

      # nav to sample show
      visit namespace_project_sample_url(@namespace, @project, @sample1)
      # verify header has loaded to prevent flakes
      assert_selector 'h1', text: @sample1.name
      ### SETUP END ###

      ### ACTIONS START ##
      # remove sample
      click_button I18n.t(:'projects.samples.show.remove_button')

      within('dialog[open]') do
        click_button I18n.t('samples.deletions.destroy_single_confirmation_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success flash msg
      assert_text I18n.t('samples.deletions.destroy.success', count: 1)
      # redirected to samples index
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                           locale: @user.locale))
      within 'tbody' do
        # remaining samples still appear selected
        assert_selector 'input[name="sample_ids[]"]:checked',
                        count: 2
        # remaining samples still appear on table
        assert_selector 'tr', count: 2
        # deleted sample row no longer exists
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
      end
      within 'tfoot' do
        assert_text 'Samples: 2'
        assert_selector 'strong[data-selection-target="selected"]', text: '2'
      end
      ### VERIFY END ###
    end

    test 'transfer dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                '3')
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with singular description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.description.singular')
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
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
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
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('samples.transfers.create.success')
      click_button I18n.t('shared.samples.success.ok_button')
      # originating project no longer has samples
      assert_text I18n.t('projects.samples.index.no_samples')

      # destination project received transferred samples
      visit namespace_project_samples_url(@namespace, @project2)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 23,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      ### VERIFY END ###
    end

    test 'dialog close button hidden during transfer samples' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      # originating project has 3 samples prior to transfer
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
        # close button available before confirming
        assert_selector 'button.dialog--close'
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
        # close button hidden during transfer
        assert_no_selector 'button.dialog--close'
        perform_enqueued_jobs only: [::Samples::TransferJob]
        ### VERIFY END ###
      end
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
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      # launch transfer dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.title')
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]
        ### ACTIONS END ###

        ### VERIFY START ###
        # samples listing should no longer appear in dialog
        assert_no_selector '#list_selections'
        # error msg displayed in dialog
        assert_text I18n.t('samples.transfers.create.no_samples_transferred_error')
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
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector '#dialog'
      within('#dialog') do
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
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # error messages in dialog
        assert_text I18n.t('samples.transfers.create.error')
        # colon is removed from translation in UI
        assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: @sample30.puid,
                                                                      sample_name: @sample30.name).gsub(':', '')
      end

      # verify sample1 and 2 transferred, sample 30 did not
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1, locale: @user.locale))
      assert_no_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_selector "tr[id='#{dom_id(@sample30)}']"

      # destination project
      visit namespace_project_samples_url(namespace, project25)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                           locale: @user.locale))
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"
      ### VERIFY END ###
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      ### SETUP START ###
      login_as users(:user28)
      namespace = groups(:group_hotel)
      project = projects(:projectHotel)
      visit namespace_project_samples_url(namespace, project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1,
                                                                               locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 1
      end
      within 'tfoot' do
        assert_text 'Samples: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # no available destination projects
        assert_selector "input[placeholder='#{I18n.t('samples.transfers.dialog.no_available_projects')}']"
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
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
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      ### VERIFY END ###
    end

    test 'empty state of transfer sample project selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end

      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
        # fill destination input
        find('input.select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('samples.transfers.dialog.empty_state')
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
      assert_selector 'div#limit-component button span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 20,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        # verify table consists of 10 samples per page
        assert_selector 'tr', count: 10
      end

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: sample3.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # verify limit is still 10
      assert_selector 'div#limit-component button span', text: '10'

      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # verify limit is still 10
      assert_selector 'div#limit-component button span', text: '10'
      ### actions and VERIFY END ###
    end

    test 'can sort samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTION and VERIFY START ###
      within('tbody tr:first-child th') do
        assert_text @sample1.puid
      end
      # sort by name
      click_on I18n.t('samples.table_component.name')

      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
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

      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### actions and VERIFY START ###
      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # set limit
      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      # verify sort is still applied
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_selector "tr[id='#{dom_id(@sample2)}']"
      assert_selector "tr[id='#{dom_id(@sample30)}']"
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample1 exists within table
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"
      ### VERIFY END ###
    end

    test 'filter by puid' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_selector "tr[id='#{dom_id(@sample2)}']"
      assert_selector "tr[id='#{dom_id(@sample30)}']"
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample2.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      # only sample2 exists within table
      assert_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"
      ### VERIFY END ###
    end

    test 'filter highlighting for sample name' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: 'sample'
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
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
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_selector "tr[id='#{dom_id(@sample2)}']"
      assert_selector "tr[id='#{dom_id(@sample30)}']"
      ### SETUP END ###

      ### ACTIONS and VERIFY START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: filter_text
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"

      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      # verify table still only contains sample1
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"

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
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"

      # verify filter text is still in filter input
      assert_selector %(input.t-search-component) do |input|
        assert_equal filter_text, input['value']
      end
      ### VERIFY END ###
    end

    test 'filter persists through page refresh' do
      ### SETUP START ###
      filter_text = @sample1.name
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: filter_text
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"

      # refresh
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1,
                                                                               locale: @user.locale))
      # verify filter is still in input field
      assert_selector %(input.t-search-component) do |input|
        assert_equal filter_text, input['value']
      end
      assert_selector "tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "tr[id='#{dom_id(@sample30)}']"
      ### VERIFY END ###
    end

    test 'sort persists through page refresh' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # apply sort
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      assert_selector '#samples-table table tbody th:first-child', text: @sample1.puid
      # change sort order from default sorting
      click_on I18n.t('samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### ACTIONS END ###

      ### VERIFY START ###
      # refresh
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # verify sort is still enabled
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      # verify table ordering is still in sorted state
      assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
      ### VERIFY END ###
    end

    test 'should import metadata with disabled feature flag' do
      ### SETUP START ###
      Flipper.disable(:metadata_import_field_selection)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('#samples-table table thead tr') do
        assert_selector 'th', count: 7
      end
      within('#samples-table table') do
        within('thead') do
          # metadatafield1 and 2 already exist, 3 does not and will be added by the import
          assert_text 'METADATAFIELD1'
          assert_text 'METADATAFIELD2'
          assert_no_text 'METADATAFIELD3'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # success msg
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      # metadatafield3 added to header
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 8
      end
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # sample 1 and 2 metadata is updated
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '20'
          assert_selector 'td:nth-child(8)', text: '30'
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: '15'
          assert_selector 'td:nth-child(7)', text: '25'
          assert_selector 'td:nth-child(8)', text: '35'
        end
      end
      ### VERIFY END ###
    end

    test 'should import metadata via csv' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('#samples-table table thead tr') do
        assert_selector 'th', count: 7
      end
      within('#samples-table table') do
        within('thead') do
          # metadatafield1 and 2 already exist, 3 does not and will be added by the import
          assert_text 'METADATAFIELD1'
          assert_text 'METADATAFIELD2'
          assert_no_text 'METADATAFIELD3'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # success msg
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      # metadatafield3 added to header
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 8
      end
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # sample 1 and 2 metadata is updated
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '20'
          assert_selector 'td:nth-child(8)', text: '30'
        end
        within("tr[id='#{dom_id(@sample2)}']") do
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('#samples-table table thead tr') do
        assert_selector 'th', count: 7
      end
      within('#samples-table table') do
        within('thead') do
          # metadatafield 3 and 4 will be added by import
          assert_no_text 'METADATAFIELD3'
          assert_no_text 'METADATAFIELD4'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xls')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_text 'metadatafield4'
          assert_no_text 'metadatafield5'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_text 'metadatafield4'
          assert_text 'metadatafield5'
          assert_selector 'li', count: 5
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # success msg
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      within('#samples-table table thead tr') do
        # metadatafield3 and 4 added to header
        assert_selector 'th', count: 9
      end
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_text 'METADATAFIELD4'
        end
        # new metadata values for sample 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '2024-01-04'
          assert_selector 'td:nth-child(8)', text: 'true'
          assert_selector 'td:nth-child(9)', text: 'A Test'
        end
        within("tr[id='#{dom_id(@sample2)}']") do
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector '#samples-table table thead tr th', count: 7
      within('#samples-table table') do
        within('thead') do
          # metadatafield 3 and 4 will be added by import
          assert_no_text 'METADATAFIELD3'
          assert_no_text 'METADATAFIELD4'
        end
        # sample 1 and 2 have no current value for metadatafield 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: ''
          assert_selector 'td:nth-child(7)', text: ''
        end
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_text 'metadatafield4'
          assert_no_text 'metadatafield5'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_text 'metadatafield4'
          assert_text 'metadatafield5'
          assert_selector 'li', count: 5
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        ### ACTIONS END ###
      end
      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      # metadatafield3 and 4 added to header
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 9
      end
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_text 'METADATAFIELD4'
        end
        # new metadata values for sample 1 and 2
        within("tr[id='#{dom_id(@sample1)}']") do
          assert_selector 'td:nth-child(6)', text: '10'
          assert_selector 'td:nth-child(7)', text: '2024-01-04'
          assert_selector 'td:nth-child(8)', text: 'true'
          assert_selector 'td:nth-child(9)', text: 'A Test'
        end
        within("tr[id='#{dom_id(@sample2)}']") do
          assert_selector 'td:nth-child(6)', text: '15'
          assert_selector 'td:nth-child(7)', text: '2024-12-31'
          assert_selector 'td:nth-child(8)', text: 'false'
          assert_selector 'td:nth-child(9)', text: 'Another Test'
        end
      end
      ### VERIFY END ###
    end

    test 'dialog close button is hidden during metadata import' do
      visit namespace_project_samples_url(@namespace, @project)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        # dialog close button available when selecting params
        assert_selector 'button.dialog--close'

        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

        assert_text I18n.t('shared.progress_bar.in_progress')
        # dialog button hidden while importing
        assert_no_selector 'button.dialog--close'
      end
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
    end

    test 'should not import metadata via invalid file type' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        assert_no_selector '#Available'
        assert_no_selector '#Selected'
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
      ### ACTIONS AND VERIFY END ###
    end

    test 'should import metadata with ignore empty values' do
      # enabled ignore empty values will leave sample metadata values unchanged
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1,
                                                                               locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within("tr[id='#{dom_id(@sample32)}']") do
        # value for metadatafield1, which is blank on the csv to import and will be left unchanged after import
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        # enable ignore empty values
        find('input#file_import_ignore_empty_values').click
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      ### VERIFY END ###

      within("tr[id='#{dom_id(@sample32)}']") do
        # unchanged value
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### VERIFY END ###
    end

    test 'should import metadata without ignore empty values' do
      # disabled ignore empty values will delete any metadata values that are empty on the import
      ### SETUP START ###
      visit namespace_project_samples_url(@subgroup12a, @project29)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1,
                                                                               locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within("tr[id='#{dom_id(@sample32)}']") do
        # value for metadatafield1, which is blank on the csv to import and will be deleted by the import
        assert_selector 'td:nth-child(6)', text: 'value1'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        # leave ignore empty values disabled
        assert_not find('input#file_import_ignore_empty_values').checked?
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      within("tr[id='#{dom_id(@sample32)}']") do
        # value is deleted for metadatafield1
        assert_selector 'td:nth-child(6)', text: ''
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with duplicate header errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 4
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # error msg
      assert_text I18n.t('services.spreadsheet_import.duplicate_column_names')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata row errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # error msg
      assert_text I18n.t('services.spreadsheet_import.missing_data_row')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata column errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
        ### VERIFY END ###
      end
    end

    test 'should partially import metadata with missing sample errors' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector '#samples-table table thead tr th', count: 7
      within('#samples-table table thead') do
        # metadatafield1 and 2 already exist, 3 does not and will be added by the import
        assert_text 'METADATAFIELD1'
        assert_text 'METADATAFIELD2'
        assert_no_text 'METADATAFIELD3'
      end
      # sample 1 has no current value for metadatafield 1 and 2
      within("tr[id='#{dom_id(@sample1)}']") do
        assert_selector 'td:nth-child(6)', text: ''
        assert_selector 'td:nth-child(7)', text: ''
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      # sample 3 does not exist in current project
      assert_text I18n.t('services.samples.metadata.import_file.sample_not_found_within_project',
                         sample_puid: 'Project 2 Sample 3')
      click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')

      # metadata still imported
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # sample 1 still imported even though sample3 (from import) does not exist
        within("tr[id='#{dom_id(@sample1)}']") do
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
      visit namespace_project_samples_url(subgroup12aa, project31)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                           locale: @user.locale))
      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # metadata that does not overwriting analysis values will still be added
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 7
      end
      within('#samples-table table thead') do
        assert_no_text 'METADATAFIELD3'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 2
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      assert_text I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                         sample_name: samples(:sample34).name, metadata_fields: 'metadatafield1')
      click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      # metadatafield3 still added
      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
        end
        # new metadata value
        within("tr[id='#{dom_id(samples(:sample34))}']") do
          assert_selector 'td:nth-child(8)', text: '20'
        end
        ### VERIFY END ###
      end
    end

    test 'uploading spreadsheet with no viable metadata should display error' do
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      visit namespace_project_samples_url(subgroup12aa, project31)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv')

        assert_text I18n.t('shared.samples.metadata.file_imports.dialog.no_valid_metadata')
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
    end

    test 'should not import metadata from ignored header values' do
      visit namespace_project_samples_url(@namespace, @project)

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # description and project_puid metadata headers do not exist
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 7
      end
      within('#samples-table table thead') do
        assert_text 'METADATAFIELD1'
        assert_no_text 'DESCRIPTION'
        assert_no_text 'PROJECT_PUID'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_ignored_headers.csv')
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.available')}']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_text 'description'
          assert_no_text 'project_puid'
          assert_no_selector 'li'
        end
        within "ul[id='#{I18n.t('shared.samples.metadata.file_imports.dialog.selected')}']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_no_text 'description'
          assert_no_text 'project_puid'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_selector '#samples-table table thead tr th', count: 8
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_no_text 'DESCRIPTION'
          assert_no_text 'PROJECT_PUID'
        end
      end
    end

    test 'should import samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))

      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))
        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      within('#samples-table table tbody') do
        # added 2 new samples
        assert_selector 'tr', count: 5
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      end
      ### VERIFY END ###
    end

    test 'should import partial data when some rows are invalid' do
      # Using short sample name to test this.
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(
        I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )

      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
        assert_no_text 'my new sample'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_short_sample_name.csv'))
        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

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
      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      within('#samples-table table tbody') do
        # added 1 new sample
        assert_selector 'tr', count: 4
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample'
      end
      ### VERIFY END ###
    end

    test 'should not import samples when file malformed' do
      # Using duplicate file header to test this.
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(
        I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )

      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_duplicate_header.csv'))
        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

      # error msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.errors.description')
      click_on I18n.t('shared.samples.spreadsheet_imports.errors.ok_button')

      within('#samples-table table tbody') do
        # added 0 new sample
        assert_selector 'tr', count: 3
        assert_no_text 'my new sample'
      end
      ### VERIFY END ###
    end

    test 'should disable select inputs if file is unselected' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(
        I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3, locale: @user.locale)
      )
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
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
    end

    test 'batch sample import metadata fields listing' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        # metadata sortable lists hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv'))
        # metadata sortable lists no longer hidden
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'
        within('#Selected') do
          assert_text 'metadata1'
          assert_text 'metadata2'
        end

        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Selected') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_text 'description'
        end

        click_button I18n.t('viral.sortable_lists_component.remove_all')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_text 'description'
        end

        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_no_text 'description'
        end

        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_no_text 'description'
        end

        within('#Selected') do
          assert_no_text 'metadata1'
          assert_no_text 'metadata2'
          assert_text 'description'
        end
        ### ACTIONS AND VERIFY END ###
      end
    end

    test 'batch sample import metadata fields listing does not render if no metadata fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        # metadata sortable lists hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))
        # metadata sortable lists still hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'

        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        # metadata sortable lists renders now that description header is available
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'

        within('#Selected') do
          assert_text 'description'
        end

        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'

        ### ACTIONS AND VERIFY END ###
      end
    end

    test 'batch sample import with partial metadata fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv'))
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'

        # make metadata selections so one metadata field is in available and one is in selected
        click_button I18n.t('viral.sortable_lists_component.remove_all')

        select 'metadata1',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Selected') do
          assert_text 'metadata1'
        end

        within('#Available') do
          assert_text 'metadata2'
        end

        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      # refresh to see new samples
      visit namespace_project_samples_url(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 5, count: 5,
                                                                           locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 5
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # only metadata1 imported and not metadata2
      within('table thead tr') do
        assert_selector 'th', count: 8
        assert_selector 'th:nth-child(6)', text: 'METADATA1'
        assert_no_text 'METADATA2'
      end
      within('table tbody') do
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_selector 'tr:first-child td:nth-child(6)', text: 'c'

        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        assert_selector 'tr:nth-child(2) td:nth-child(6)', text: 'a'
      end
    end

    test 'singular clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.clones.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'plural clone dialog description' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t(
          'samples.clones.dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
      end
      ### VERIFY END ###
    end

    test 'clone dialog sample listing' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      # verify samples 1 and 2 do not exist in project2
      within('#samples-table table tbody') do
        assert_no_text @sample1.name
        assert_no_text @sample2.name
      end

      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1, :checkbox)}").click
        find("input##{dom_id(@sample2, :checkbox)}").click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      # samples still exist within samples table of originating project
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end

      # samples now exist in project2 samples table
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 22,
                                                                           locale: @user.locale))
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end
      ### VERIFY END ###
    end

    test 'dialog close button hidden while cloning samples' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1, :checkbox)}").click
        find("input##{dom_id(@sample2, :checkbox)}").click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
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
        click_on I18n.t('samples.clones.dialog.submit_button')

        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('shared.progress_bar.in_progress')
        # close button hidden during cloning
        assert_no_selector 'button.dialog--close'
        perform_enqueued_jobs only: [::Samples::CloneJob]

        ### VERIFY END ###
      end
    end

    test 'should not clone samples with session storage cleared' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('samples.clones.dialog.title')
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]
        ### ACTIONS END ###

        ### VERIFY START ###
        # sample listing should not be in error dialog
        assert_no_selector '#list_selections'
        # error msg
        assert_text I18n.t('samples.clones.create.no_samples_cloned_error')
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                           locale: @user.locale))
      # sample30's name already exists in project25 samples table, samples1 and 2 do not
      within('#samples-table table tbody') do
        assert_no_text @sample1.name
        assert_no_text @sample2.name
        assert_text @sample30.name
      end
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input.select2-input').click
        find("li[data-value='#{project25.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]
        ### ACTIONS END ###

        ### VERIFY START ###
        # errors that a sample with the same name as sample30 already exists in project25
        assert_text I18n.t('samples.clones.create.error')
        assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample30.puid,
                                                                   sample_name: @sample30.name).gsub(':', '')
        click_on I18n.t('shared.samples.errors.ok_button')
      end

      visit namespace_project_samples_url(namespace, project25)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                           locale: @user.locale))
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ####
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        find('input.select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('samples.clones.dialog.empty_state')
        ### VERIFY END ###
      end
    end

    test 'no available destination projects to clone samples' do
      ### SETUP START ###
      sign_in users(:jean_doe)
      visit namespace_project_samples_url(namespaces_user_namespaces(:john_doe_namespace), projects(:john_doe_project2))
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1,
                                                                               locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 1
      end
      within 'tfoot' do
        assert_text 'Samples: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert "input[placeholder='#{I18n.t('samples.clones.dialog.no_available_projects')}']"
      end
      ### VERIFY END ###
    end

    test 'updating sample selection during sample cloning' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      # verify no samples currently selected in destination project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
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
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      # verify no samples selected anymore
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      # verify destination project still has no selected samples and one additional sample
      visit namespace_project_samples_url(@namespace, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))

      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      ### VERIFY END
    end

    test 'selecting / deselecting all samples' do
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
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
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 3
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      # apply filter
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: samples(:sample1).name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

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
      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: ' '
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within('tbody tr:first-child') do
        # select sample1
        all('input[type="checkbox"]')[0].click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#multiple-deletions-dialog') do
        assert_text I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.description.singular',
                           sample_name: @sample1.name)
      end
      ### VERIFY END ###
    end

    test 'plural description within delete samples dialog' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#multiple-deletions-dialog') do
        assert_text I18n.t(
          'samples.deletions.destroy_multiple_confirmation_dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '3'
      end
      ### VERIFY END ###
    end

    test 'samples listing within delete samples dialog' do
      ### SETUP START ###
      samples = @project.samples.pluck(:puid, :name)
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#multiple-deletions-dialog #list_selections') do
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      within('#multiple-deletions-dialog') do
        assert_selector 'form[data-infinite-scroll-target="pageForm"]'
        sleep 1
        click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.metadatafield1']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
        assert_no_selector "tr[id='#{dom_id(@sample2)}']"
        # sample30 found
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.example_date']").select_option
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: (DateTime.strptime(sample62.metadata['example_date'],
                                                                            '%Y-%m-%d') - 1.day).strftime('%Y-%m-%d')
          end
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
            find("select[name$='[field]']").find("option[value='metadata.example_date']").select_option
            find("select[name$='[operator]']").find("option[value='<=']").select_option
            find("input[name$='[value]']").fill_in with: (DateTime.strptime(sample62.metadata['example_date'],
                                                                            '%Y-%m-%d') + 1.day).strftime('%Y-%m-%d')
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(sample61)}']"
        assert_no_selector "tr[id='#{dom_id(sample63)}']"
        # sample62 found
        assert_selector "tr[id='#{dom_id(sample62)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.example_float']").select_option
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: sample62.metadata['example_float'].to_f - 0.1
          end
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
            find("select[name$='[field]']").find("option[value='metadata.example_float']").select_option
            find("select[name$='[operator]']").find("option[value='<=']").select_option
            find("input[name$='[value]']").fill_in with: sample62.metadata['example_float'].to_f + 0.1
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(sample61)}']"
        assert_no_selector "tr[id='#{dom_id(sample63)}']"
        # sample62 found
        assert_selector "tr[id='#{dom_id(sample62)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.example_integer']").select_option
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: sample62.metadata['example_integer'].to_i - 1
          end
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
            find("select[name$='[field]']").find("option[value='metadata.example_integer']").select_option
            find("select[name$='[operator]']").find("option[value='<=']").select_option
            find("input[name$='[value]']").fill_in with: sample62.metadata['example_integer'].to_i + 1
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(sample61)}']"
        assert_no_selector "tr[id='#{dom_id(sample63)}']"
        # sample62 found
        assert_selector "tr[id='#{dom_id(sample62)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(sample61)}']"
        assert_selector "tr[id='#{dom_id(sample62)}']"
        assert_selector "tr[id='#{dom_id(sample63)}']"
      end
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple conditions' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.metadatafield1']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
          end
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
            find("select[name$='[field]']").find("option[value='metadata.metadatafield2']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield2']
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
        assert_no_selector "tr[id='#{dom_id(@sample2)}']"
        # sample30 found
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple conditions that fail validation' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.metadatafield1']").select_option
            find("select[name$='[operator]']").find("option[value='contains']").select_option
            find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
          end
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
            find("select[name$='[field]']").find("option[value='metadata.metadatafield1']").select_option
            find("select[name$='[operator]']").find("option[value='contains']").select_option
            find("input[name$='[value]']").fill_in with: @sample30.metadata['metadatafield1']
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
        assert_text I18n.t(:'validators.advanced_search_group_validator.uniqueness_error',
                           unique_field: 'metadata.metadatafield1')
      end
      ### actions and VERIFY END ###
    end

    test 'filter samples with advanced search using multiple groups' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### SETUP END ###

      ### actions and VERIFY START ###
      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='name']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample1.name
          end
        end
        click_button I18n.t(:'advanced_search_component.add_group_button')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='name']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample2.name
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        # sample1 & sample2 found
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_no_selector "tr[id='#{dom_id(@sample30)}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample30)}']"
      end
      ### actions and VERIFY END ###
    end

    test 'can update metadata value that is not from an analysis' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within('table thead tr') do
        assert_selector 'th', count: 5
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 7
      end

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end

      within('table thead tr') do
        assert_selector 'th', count: 7
      end
      ### SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[contenteditable="true"]'
        find('td:nth-child(7)').click

        find('td:nth-child(7)').send_keys('value2')
        find('td:nth-child(7)').native.send_keys(:return)
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector 'td:nth-child(7)[contenteditable="true"]', text: 'value2'
      end
      assert_text I18n.t('samples.editable_cell.update_success')

      assert_no_selector 'dialog[open]'
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')
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

      within('table tbody tr:nth-child(1)') do
        ### VERIFY START ###
        assert_no_selector 'td:nth-child(6)[contenteditable="true"]'
        ### VERIFY END ###
      end
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

      within('table thead tr') do
        assert_selector 'th', count: 7
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample2.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'
      ### SETUP END ###

      ### VERIFY START ###
      within('table tbody tr:first-child td:nth-child(7)') do
        assert_no_selector "form[method='get']"
      end
      ### VERIFY END ###
    end

    test 'shows confirmation dialog when editing metadata field with changes' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      within('table thead tr') do
        assert_selector 'th', count: 5
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 7
      end

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[contenteditable="true"]'
        find('td:nth-child(7)').click

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
      within('table tbody tr:first-child td:nth-child(7)') do
        assert_text 'New Value'
      end
      ### VERIFY END ###
    end

    test 'shows confirmation dialog can be cancelled resetting the value' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)
      within('table thead tr') do
        assert_selector 'th', count: 5
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 7
      end

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end

      within('table thead tr') do
        assert_selector 'th', count: 7
      end
      ### SETUP END ###

      within('table tbody tr:first-child') do
        ### ACTIONS START ###
        assert_selector 'td:nth-child(7)[contenteditable="true"]'
        find('td:nth-child(7)').click

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
      within('table tbody tr:first-child td:nth-child(7)') do
        assert_no_text 'New Value'
      end
      ### VERIFY END ###
    end

    test 'linelist export test' do
      ### SETUP START ###
      visit namespace_project_samples_url(@namespace, @project)

      # Assert that the Export button is disabled when no samples are selected
      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]',
                      text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      within '#samples-table table tbody' do
        assert_selector 'tr', count: 3
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'projects.samples.index.select_all_button')
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.linelist_export')
      assert_selector "div[data-controller='infinite-scroll viral--sortable-lists--two-lists-selection']"
      assert_no_selector 'ul#Selected li', text: 'metadatafield1'
      select 'Project Template with existing fields', from: I18n.t('data_exports.new.template_select_label')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_no_selector 'ul#Available li', text: 'metadatafield1'
      assert_selector 'ul#Selected li', text: 'metadatafield1', count: 1
      ### VERIFY END ###
    end

    test 'pagy overflow redirects to first page' do
      project = projects(:project38)
      sample = samples(:bulk_sample19)

      visit namespace_project_samples_url(project.namespace.parent, project)

      within('#samples-table table') do
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 20
          # row contents
        end
      end

      assert_link exact_text: I18n.t(:'viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.previous')

      click_on I18n.t(:'viral.pagy.pagination_component.next')

      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')

      # samples table
      within('#samples-table table') do
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 20
          # row contents
        end
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: sample.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # Search for PUID
      #        within('#samples-table table') do
      within('tbody') do
        # rows
        assert_selector '#samples-table table tbody tr', count: 11

        within("tr[id='#{dom_id(sample)}']") do
          assert_selector 'th:first-child', text: sample.puid
          assert_selector 'td:nth-child(2)', text: sample.name
        end
      end
    end

    def long_filter_text
      text = (1..500).map { |n| "sample#{n}" }.join(', ')
      "#{text}, #{@sample1.name}" # Need to comma to force the tag to be created
    end
  end
end
