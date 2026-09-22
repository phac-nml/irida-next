# frozen_string_literal: true

require 'application_system_test_case'
# start refactoring
module Projects
  module Samples
    class MetadataTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

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

      test 'update metadata key and value at same time' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within '#sample-metadata' do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('common.actions.update')
          end
        end

        within %(turbo-frame[id="sample_modal"]) do
          assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
          assert_selector 'input#sample_update_field_key_input', count: 1
          assert_selector 'input#sample_update_field_value_input', count: 1
          find('input#sample_update_field_key_input').fill_in with: 'newMetadataKey'
          find('input#sample_update_field_value_input').fill_in with: 'newMetadataValue'
          click_on I18n.t('common.actions.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'metadatafield1'
        assert_no_text 'value1'
        assert_text 'newmetadatakey' # NOTE: downcase
        assert_text 'newMetadataValue'
      end

      test 'add both new and existing metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'metadatafield2'
        assert_selector 'table tbody tr:nth-child(2) td:nth-child(3)', text: 'value2'

        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        fill_in 'sample_key_0', with: 'metadatafield1'
        fill_in 'sample_value_0', with: 'newValue1'
        fill_in 'sample_key_1', with: 'metadatafield3'
        fill_in 'sample_value_1', with: 'value3'
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadatafield3')
        assert_text I18n.t('projects.samples.metadata.fields.create.single_key_exists', key: 'metadatafield1')
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 3
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafield3'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value3'
      end

      test 'delete metadata key added by user' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        click_on I18n.t('common.actions.delete'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')
        assert_text I18n.t('projects.samples.show.metadata.actions.delete_confirm', deleted_key: 'metadatafield1')
        click_button I18n.t('common.controls.confirm')

        assert_text I18n.t('projects.samples.metadata.destroy.success', deleted_key: 'metadatafield1')
        assert_no_selector 'h1.dialog--title', text: I18n.t('components.confirmation.title')

        assert_selector 'table tbody tr', count: 1
        assert_no_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_no_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield2'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value2'
      end

      test 'delete multiple metadata keys by delete metadata modal' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafield2'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value2'
        check 'metadata_0'
        check 'metadata_1'
        click_button I18n.t('projects.samples.metadata.table.delete_metadata_button')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.deletions.modal.title')
        assert_text 'metadatafield1'
        assert_text 'value1'
        assert_text 'metadatafield2'
        assert_text 'value2'
        click_button 'destroy-metadata-button'

        assert_text I18n.t('projects.samples.metadata.deletions.destroy.multi_success',
                           deleted_keys: 'metadatafield1, metadatafield2')

        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.deletions.modal.title')
        assert_no_selector 'table'
        assert_no_text 'metadatafield1'
        assert_no_text 'value1'
        assert_no_text 'metadatafield2'
        assert_no_text 'value2'
        assert_selector "[id^='empty-state-title-']", text: I18n.t('projects.samples.metadata.table.no_metadata')
        assert_selector "[id^='empty-state-desc-'] span",
                        text: I18n.t('projects.samples.metadata.table.no_associated_metadata')
      end
    end
  end
end
