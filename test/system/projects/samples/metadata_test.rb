# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class AttachmentsTest < ApplicationSystemTestCase
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

      test 'view sample metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        assert_text I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.tabs.metadata')

        within '#sample-metadata table' do
          assert_text I18n.t('projects.samples.show.table_header.key').upcase
          assert_selector 'tbody tr', count: 2
          assert_text 'metadatafield1'
          assert_text 'value1'
          assert_text 'metadatafield2'
          assert_text 'value2'
        end
      end

      test 'update metadata key' do
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
          click_on I18n.t('common.actions.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'metadatafield1'
        assert_text 'newmetadatakey' # NOTE: downcase
        assert_text 'value1'
      end

      test 'update metadata value' do
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
          find('input#sample_update_field_value_input').fill_in with: 'newMetadataValue'
          click_on I18n.t('common.actions.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'value1'
        assert_text 'metadatafield1'
        assert_text 'newMetadataValue'
      end

      test 'update both metadata key and value at same time' do
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

      test 'cannot update metadata with empty key' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr#metadatafield1_field'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_no_text I18n.t('services.samples.metadata.update_fields.key_required')
        fill_in 'sample_update_field_key_input', with: ''
        fill_in 'sample_update_field_value_input', with: 'newValue'
        click_on 'update-metadata-submit-btn'
        assert_text I18n.t('services.samples.metadata.update_fields.key_required')
      end

      test 'cannot update metadata with empty value' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr#metadatafield1_field'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_no_text I18n.t('services.samples.metadata.update_fields.value_required')
        fill_in 'sample_update_field_key_input', with: 'newKey'
        fill_in 'sample_update_field_value_input', with: ''
        click_on 'update-metadata-submit-btn'
        assert_text I18n.t('services.samples.metadata.update_fields.value_required')
      end

      test 'user with access level < Maintainer cannot view update action' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within '#sample-metadata' do
          assert_no_text I18n.t('projects.samples.show.table_header.action').upcase
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

        within '#sample-metadata' do
          assert_text 'metadatafield1'
          assert_text "#{I18n.t('models.sample.analysis')} 1"
          within('tbody tr:first-child td:last-child') do
            assert_no_text I18n.t('common.actions.update')
          end
        end
      end

      test 'add single new metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        fill_in 'sample_key_0', with: 'metadatafield3'
        fill_in 'sample_value_0', with: 'value3'
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadatafield3')
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 3

        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafield3'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value3'
      end

      test 'add multiple new metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        fill_in 'sample_key_0', with: 'metadatafield3'
        fill_in 'sample_value_0', with: 'value3'
        fill_in 'sample_key_1', with: 'metadatafield4'
        fill_in 'sample_value_1', with: 'value4'
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: %w[metadatafield3 metadatafield4].join(', '))
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 4

        assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: 'metadatafield3'
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(3)', text: 'value3'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafield4'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value4'
      end

      test 'Field required error messages are displayed when field left blank and successfully
      created once corrected' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        within %(turbo-frame[id="sample_modal"]) do
          click_on I18n.t('projects.samples.metadata.form.create_field_button')

          all('input.keyInput')[1].fill_in with: 'metadatafield4'
          all('input.valueInput')[1].fill_in with: 'value4'
          click_on I18n.t('projects.samples.metadata.form.submit_button')

          # First row (key and value) are left blank
          key_id = all('input.keyInput')[0][:id]
          value_id = all('input.valueInput')[0][:id]

          find(:xpath, %(//*[@id="#{key_id}_error"]//span[@class="grow"]),
               text: I18n.t('projects.samples.metadata.new_metadata_modal.required_error.key'))
          find(:xpath, %(//*[@id="#{value_id}_error"]//span[@class="grow"]),
               text: I18n.t('projects.samples.metadata.new_metadata_modal.required_error.value'))

          # Fill in empty key and value
          all('input.keyInput')[0].fill_in with: 'metadatafieldnew'
          all('input.valueInput')[0].fill_in with: 'valueNew'

          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: %w[metadatafield4 metadatafieldnew].join(', '))

        assert_selector 'table tbody tr', count: 4
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: 'metadatafield4'
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(3)', text: 'value4'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafieldnew'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'valueNew'
      end

      test 'add single existing metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'

        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        fill_in 'sample_key_0', with: 'metadatafield1'
        fill_in 'sample_value_0', with: 'newValue1'
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('services.samples.metadata.fields.single_all_keys_exist', key: 'metadatafield1')
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
      end

      test 'add multiple existing metadata' do
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
        fill_in 'sample_key_1', with: 'metadatafield2'
        fill_in 'sample_value_1', with: 'newValue2'
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('services.samples.metadata.fields.multi_all_keys_exist',
                           keys: %w[metadatafield1 metadatafield2].join(', '))
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
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

      test 'add new metadata after deleting fields' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')

        fill_in 'sample_key_0', with: 'metadatafield3'
        fill_in 'sample_value_0', with: 'value3'
        fill_in 'sample_key_1', with: 'metadatafield4'
        fill_in 'sample_value_1', with: 'value4'
        fill_in 'sample_key_2', with: 'metadatafield5'
        fill_in 'sample_value_2', with: 'value5'
        fill_in 'sample_key_3', with: 'metadatafield6'
        fill_in 'sample_value_3', with: 'value6'

        click_button 'delete_1'
        click_button 'delete_2'

        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: %w[metadatafield3 metadatafield6].join(', '))
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_no_text 'metadatafield4'
        assert_no_text 'value4'
        assert_no_text 'metadatafield5'
        assert_no_text 'value5'

        assert_selector 'table tbody tr', count: 4
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: 'metadatafield3'
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(3)', text: 'value3'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadatafield6'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value6'
      end

      test 'clicking remove button in add modal with one metadata field clears inputs but doesn\'t delete field' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        assert_selector 'input.keyInput', count: 1
        assert_selector 'input.valueInput', count: 1

        click_button 'delete_0'

        assert_selector 'input.keyInput', count: 1
        assert_selector 'input.valueInput', count: 1
      end

      test 'user with access < Maintainer cannot see add metadata' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_no_text I18n.t('projects.samples.metadata.table.add_metadata')
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

      test 'delete metadata key added by anaylsis' do
        @subgroup12aa = groups(:subgroup_twelve_a_a)
        @project31 = projects(:project31)
        @sample34 = samples(:sample34)

        visit namespace_project_sample_url(@subgroup12aa, @project31, @sample34)

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

      test 'delete one metadata key by delete metadata modal' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        check 'metadata_0'
        click_button I18n.t('projects.samples.metadata.table.delete_metadata_button')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.deletions.modal.title')
        assert_text 'metadatafield1'
        assert_text 'value1'
        click_button 'destroy-metadata-button'

        assert_text I18n.t('projects.samples.metadata.deletions.destroy.single_success', deleted_key: 'metadatafield1')
        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.deletions.modal.title')

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

      test 'user with access < Maintainer cannot view delete checkboxes, delete action or delete metadata button' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector 'table tbody tr', count: 2
        assert_selector 'table tbody tr:first-child td:first-child', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'value1'
        assert_selector 'table tbody tr:last-child td:first-child', text: 'metadatafield2'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'value2'
        assert_no_selector 'input[type="checkbox"]'
        assert_no_text I18n.t('projects.samples.show.table_header.action').upcase

        assert_no_selector 'button', text: I18n.t('projects.samples.metadata.table.add_metadata')
        assert_no_selector 'button', text: I18n.t('projects.samples.metadata.table.delete_metadata_button')
      end

      test 'removing metadata field completely removes wrapper container and all contents' do
        project = projects(:project29)
        sample = samples(:sample32)
        group = groups(:subgroup_twelve_a)

        visit namespace_project_sample_url(group, project, sample)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          # Add multiple fields
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          click_on I18n.t('projects.samples.metadata.form.create_field_button')

          # Fill in the fields
          all('input.keyInput')[0].fill_in with: 'testkey1'
          all('input.valueInput')[0].fill_in with: 'testvalue1'
          all('input.keyInput')[1].fill_in with: 'testkey2'
          all('input.valueInput')[1].fill_in with: 'testvalue2'
          all('input.keyInput')[2].fill_in with: 'testkey3'
          all('input.valueInput')[2].fill_in with: 'testvalue3'

          # Get the ID of the second field's key input before removal
          second_field_key_input = all('input.keyInput')[1]
          key_input_id = second_field_key_input[:id]

          # Find the wrapper container that contains this input
          wrapper = second_field_key_input.find(:xpath, 'ancestor::div[contains(@class, "metadata-field-wrapper")]')
          wrapper_id = wrapper[:id] if wrapper[:id]

          # Extract the field ID from the input ID (e.g., "sample_key_1" -> "1")
          field_id_match = key_input_id.match(/key_(\d+)/)
          field_id = field_id_match ? field_id_match[1] : nil

          # Verify the wrapper container exists before removal
          assert_selector '.metadata-field-wrapper', count: 3

          # Verify the inputField div exists within the wrapper
          within wrapper do
            assert_selector '.inputField', count: 1
          end

          # Verify the error div exists
          if field_id
            key_error_div_id = "sample_key_#{field_id}_error"
            value_error_div_id = "sample_value_#{field_id}_error"
            assert_selector "##{key_error_div_id}", count: 1, visible: :all
            assert_selector "##{value_error_div_id}", count: 1, visible: :all
          end

          # Verify the inputs exist within the wrapper
          within wrapper do
            assert_selector "input##{key_input_id}", count: 1
          end

          # Remove the second field (index 1)
          all('button[data-action="projects--samples--metadata--create#removeField"]')[1].click

          # Verify the wrapper container is completely gone
          assert_no_selector "##{wrapper_id}" if wrapper_id.present?
          assert_selector '.metadata-field-wrapper', count: 2

          # Verify the key and value inputs are gone
          assert_no_selector "input##{key_input_id}"

          # Verify the error div is gone
          if field_id
            key_error_div_id = "sample_key_#{field_id}_error"
            value_error_div_id = "sample_value_#{field_id}_error"
            assert_no_selector "##{key_error_div_id}", visible: :all
            assert_no_selector "##{value_error_div_id}", visible: :all
          end

          # Verify only 2 fields remain (indices 0 and 1, which were originally 0 and 2)
          assert_selector 'input.keyInput', count: 2
          assert_selector 'input.valueInput', count: 2
          assert_selector '.metadata-field-wrapper', count: 2

          # Verify the remaining fields still have their values
          assert_equal 'testkey1', all('input.keyInput')[0].value
          assert_equal 'testvalue1', all('input.valueInput')[0].value
          assert_equal 'testkey3', all('input.keyInput')[1].value
          assert_equal 'testvalue3', all('input.valueInput')[1].value

          # Verify no trace of the removed field's inputs or error divs exist
          assert_no_selector "input[id*='testkey2']"
          assert_no_selector "input[value='testvalue2']"
        end
      end

      test 'update metadata key and value with stripping leading/trailing whitespaces' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr', count: 2

        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        fill_in 'sample_update_field_key_input', with: '          newMetadataKey              '
        fill_in 'sample_update_field_value_input', with: '          newMetadataValue              '
        click_on 'update-metadata-submit-btn'

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_selector 'table tbody tr', count: 2
        assert_no_text 'metadatafield1'
        assert_no_text 'value1'
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield2'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value2'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'newmetadatakey'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'newMetadataValue'
      end

      test 'update metadata key and value with multiple inner whitespaces' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr', count: 2

        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        fill_in 'sample_update_field_key_input', with: '   new Metadata  Key    '
        fill_in 'sample_update_field_value_input', with: '  new  Metadata    Value  '
        click_on 'update-metadata-submit-btn'

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_selector 'table tbody tr', count: 2
        assert_no_text 'metadatafield1'
        assert_no_text 'value1'
        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield2'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value2'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'new metadata key'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'new Metadata Value'
      end

      test 'update metadata key with only leading/trailing whitespaces on old key will not update' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr', count: 2

        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        fill_in 'sample_update_field_key_input', with: '   metadatafield1    '
        click_on 'update-metadata-submit-btn'

        assert_no_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_text I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')
      end

      test 'update metadata value with only leading/trailing whitespaces on old value will not update' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        assert_selector '#sample-metadata'
        assert_selector 'table tbody tr', count: 2

        assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
        assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
        click_button I18n.t('common.actions.update'), match: :first

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        fill_in 'sample_update_field_value_input', with: '   value1    '
        click_on 'update-metadata-submit-btn'

        assert_no_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_text I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')
      end

      test 'add new metadata with whitespaces' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        fill_in 'sample_key_0', with: '    metadata       field   3   '
        fill_in 'sample_value_0', with: '    value      3   '
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadata field 3')

        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 3
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadata field 3'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value 3'
      end

      test 'update metadata by adding extra spaces induces error' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        # create metadata field first
        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        fill_in 'sample_key_0', with: '    metadata       field   3   '
        fill_in 'sample_value_0', with: '    value      3   '
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadata field 3')

        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 3
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadata field 3'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value 3'

        within('table tbody tr:last-child') do
          click_button I18n.t('common.actions.update')
        end

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.show.metadata.update.update_metadata')
        fill_in 'sample_update_field_key_input', with: '   metadata     field 3    '
        click_on 'update-metadata-submit-btn'

        assert_no_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_text I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')
      end

      test 'add multiple new metadata with same key and different whitespaces' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_selector 'table tbody tr', count: 2
        click_on I18n.t('projects.samples.metadata.table.add_metadata')

        assert_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        click_on I18n.t('projects.samples.metadata.form.create_field_button')
        fill_in 'sample_key_0', with: '    metadata       field   3   '
        fill_in 'sample_value_0', with: '    value      3   '
        fill_in 'sample_key_1', with: 'metadata   field   3'
        fill_in 'sample_value_1', with: '    different value   '
        fill_in 'sample_key_2', with: 'metadata   field   4'
        fill_in 'sample_value_2', with: '     value 4 '
        click_on I18n.t('projects.samples.metadata.form.submit_button')

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: ['metadata field 3', 'metadata field 4'].join(', '))

        assert_no_selector 'h1.dialog--title', text: I18n.t('projects.samples.metadata.new_metadata_modal.title')

        assert_selector 'table tbody tr', count: 4
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: 'metadata field 3'
        assert_selector 'table tbody tr:nth-child(3) td:nth-child(3)', text: 'different value'
        assert_selector 'table tbody tr:last-child td:nth-child(2)', text: 'metadata field 4'
        assert_selector 'table tbody tr:last-child td:nth-child(3)', text: 'value 4'
      end
    end
  end
end
