# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class CloneTest < ApplicationSystemTestCase
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
            assert_text @sample1.puid
            assert_text @sample1.name
            assert_text @sample2.puid
            assert_text @sample2.name
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
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
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
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
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
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
        visit namespace_project_samples_url(namespaces_user_namespaces(:john_doe_namespace),
                                            projects(:john_doe_project2))
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
            assert_text @sample1.name
            assert_text @sample1.puid
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']", wait: 1).click
          click_on I18n.t('projects.samples.clones.dialog.submit_button')
        end
        ### ACTIONS END ###

        ### VERIFY START ###
        sleep 1
        # flash msg
        assert_text I18n.t('projects.samples.clones.create.success')
        # verify no samples selected anymore
        within 'tfoot' do
          assert_text "#{I18n.t('samples.table_component.counts.samples')}: 3"
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end

        # verify destination project still has no selected samples and one additional sample
        visit namespace_project_samples_url(@namespace, @project2)

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
    end
  end
end
