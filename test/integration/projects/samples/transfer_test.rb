# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class TransferTest < ActionDispatch::IntegrationTest
      include ActionView::Helpers::SanitizeHelper

      setup do
        Flipper.enable(:advanced_search_with_auto_complete)

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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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

      ### Test with V1 sample transfer ###

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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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

      test 'updating sample selection during transfer samples' do
        ### SETUP START ###
        visit namespace_project_samples_url(@namespace, @project2)

        # verify no samples currently selected in destination project
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'

        visit namespace_project_samples_url(@namespace, @project)
        # verify samples table has loaded to prevent flakes
        assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                        locale: @user.locale))
        ### SETUP END ###

        ### ACTIONS START ###
        # select 1 sample to transfer
        find('table tbody tr:first-child th input[type="checkbox"]').click

        # verify 1 sample selected in originating project
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '1'

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
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 2"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'

        # verify destination project still has no selected samples and one additional sample
        visit namespace_project_samples_url(@namespace, @project2)
        # verify samples table has loaded to prevent flakes
        assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                                        locale: @user.locale))
        assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'
        ### VERIFY END ###
      end

      ### Test with V2 sample transfer ###

      test 'transfer samples v2' do
        ### SETUP START ###
        Flipper.enable(:v2_sample_transfer)

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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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

        perform_enqueued_jobs only: [::Samples::TransferJobV2]
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
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'dialog close button hidden during transfer samples v2' do
        ### SETUP START ###
        Flipper.enable(:v2_sample_transfer)

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
        perform_enqueued_jobs only: [::Samples::TransferJobV2]
        assert_performed_jobs 1
        assert_no_text I18n.t('shared.progress_bar.in_progress')
        # flash msg
        assert_text I18n.t('samples.transfers.create.success')
        click_button I18n.t('shared.samples.success.ok_button')

        assert_no_selector 'dialog[open]'
        ### VERIFY END ###
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'should not transfer samples with session storage cleared v2' do
        ### SETUP START ###
        Flipper.enable(:v2_sample_transfer)

        visit namespace_project_samples_url(@namespace, @project)
        assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                        locale: @user.locale))
        ### SETUP END ###

        ### ACTIONS START ###
        # select samples
        click_button I18n.t('common.controls.select_all')
        assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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

        perform_enqueued_jobs only: [::Samples::TransferJobV2]
        assert_performed_jobs 1
        assert_no_text I18n.t('shared.progress_bar.in_progress')

        # samples listing should no longer appear in dialog
        assert_no_selector '#list_selections'
        # error msg displayed in dialog
        assert_text I18n.t('samples.transfers.create.no_samples_transferred_error')
        ### VERIFY END ###
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'transfer samples with and without same name in destination project v2' do
        # only samples without a matching name to samples in destination project will transfer

        ### SETUP START ###
        Flipper.enable(:v2_sample_transfer)

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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'
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

        perform_enqueued_jobs only: [::Samples::TransferJobV2]
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
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'updating sample selection during transfer samples v2' do
        ### SETUP START ###
        Flipper.enable(:v2_sample_transfer)

        visit namespace_project_samples_url(@namespace, @project2)

        # verify no samples currently selected in destination project
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 20"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'

        visit namespace_project_samples_url(@namespace, @project)
        # verify samples table has loaded to prevent flakes
        assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                        locale: @user.locale))
        ### SETUP END ###

        ### ACTIONS START ###
        # select 1 sample to transfer
        find('table tbody tr:first-child th input[type="checkbox"]').click

        # verify 1 sample selected in originating project
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 3"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '1'

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

        perform_enqueued_jobs only: [::Samples::TransferJobV2]
        assert_performed_jobs 1
        assert_no_text I18n.t('shared.progress_bar.in_progress')

        click_button I18n.t('shared.samples.success.ok_button')

        assert_no_selector 'dialog[open]'

        # verify no samples selected anymore
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 2"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'

        # verify destination project still has no selected samples and one additional sample
        visit namespace_project_samples_url(@namespace, @project2)
        # verify samples table has loaded to prevent flakes
        assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                                        locale: @user.locale))
        assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 0
        assert_selector 'table tfoot tr', text: "#{I18n.t('samples.table_component.counts.samples')}: 21"
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '0'
        ### VERIFY END ###
      ensure
        Flipper.disable(:v2_sample_transfer)
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
        assert_selector 'table tfoot tr', text: 'Samples: 1'
        assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '1'
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
        assert_selector 'table tfoot tr', text: 'Samples: 1'
        assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '1'
        click_button I18n.t('shared.samples.actions_dropdown.label')
        click_button I18n.t('shared.samples.actions_dropdown.transfer')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
        # no available destination projects
        assert_field placeholder: I18n.t('samples.transfers.dialog.no_available_projects'), disabled: true
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
        assert_selector 'table tfoot tr', text: 'Samples: 3'
        assert_selector 'table tfoot tr strong[data-selection-target="selected"]', text: '3'

        # launch dialog
        click_button I18n.t('shared.samples.actions_dropdown.label')
        click_button I18n.t('shared.samples.actions_dropdown.transfer')

        assert_selector 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
        # fill destination input
        find('input.select2-input').click
        find('input.select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('samples.transfers.dialog.empty_state')
        ### VERIFY END ###
      end
    end
  end
end
