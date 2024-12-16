# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class TransferTest < ApplicationSystemTestCase
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

        Project.reset_counters(@project.id, :samples_count)

        Sample.reindex
        Searchkick.enable_callbacks
      end

      teardown do
        Searchkick.disable_callbacks
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
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          # select destination project
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
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
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
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
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
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
            assert_text @sample1.name
            assert_text @sample1.puid
          end
          find('input#select2-input').click
          click_button @project2.puid
          # find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
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
        assert_selector 'h1', text: 'Samples'
        assert_selector '#samples-table'
        within 'tfoot' do
          assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end

        click_button I18n.t(:'projects.samples.index.select_all_button')

        within 'tfoot' do
          assert_text "#{I18n.t('samples.table_component.counts.samples')}: 21"
          assert_selector 'strong[data-selection-target="selected"]', text: '21'
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
    end
  end
end
