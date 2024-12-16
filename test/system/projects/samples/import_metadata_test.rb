# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class ImportMetadataTest < ApplicationSystemTestCase
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
    end
  end
end
