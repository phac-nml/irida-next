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

        within %(turbo-frame[id="table-listing"]) do
          assert_text I18n.t('projects.samples.show.table_header.key').upcase
          assert_selector 'table#metadata-table tbody tr', count: 2
          assert_text 'metadatafield1'
          assert_text 'value1'
          assert_text 'metadatafield2'
          assert_text 'value2'
        end
      end

      test 'update metadata key' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
          end
        end

        within %(turbo-frame[id="sample_modal"]) do
          assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
          assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
          assert_selector 'input#sample_update_field_value_value1', count: 1
          find('input#sample_update_field_key_metadatafield1').fill_in with: 'newMetadataKey'
          click_on I18n.t('projects.samples.show.metadata.update.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'metadatafield1'
        assert_text 'newmetadatakey' # NOTE: downcase
        assert_text 'value1'
      end

      test 'update metadata value' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
          end
        end

        within %(turbo-frame[id="sample_modal"]) do
          assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
          assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
          assert_selector 'input#sample_update_field_value_value1', count: 1
          find('input#sample_update_field_value_value1').fill_in with: 'newMetadataValue'
          click_on I18n.t('projects.samples.show.metadata.update.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'value1'
        assert_text 'metadatafield1'
        assert_text 'newMetadataValue'
      end

      test 'update both metadata key and value at same time' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
          end
        end

        within %(turbo-frame[id="sample_modal"]) do
          assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
          assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
          assert_selector 'input#sample_update_field_value_value1', count: 1
          find('input#sample_update_field_key_metadatafield1').fill_in with: 'newMetadataKey'
          find('input#sample_update_field_value_value1').fill_in with: 'newMetadataValue'
          click_on I18n.t('projects.samples.show.metadata.update.update')
        end

        assert_text I18n.t('projects.samples.metadata.fields.update.success')
        assert_no_text 'metadatafield1'
        assert_no_text 'value1'
        assert_text 'newmetadatakey' # NOTE: downcase
        assert_text 'newMetadataValue'
      end

      test 'cannot update metadata key with key that already exists' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.update')
          end
        end

        within %(turbo-frame[id="sample_modal"]) do
          assert_text I18n.t('projects.samples.show.metadata.update.update_metadata')
          assert_selector 'input#sample_update_field_key_metadatafield1', count: 1
          assert_selector 'input#sample_update_field_value_value1', count: 1
          find('input#sample_update_field_key_metadatafield1').fill_in with: 'metadatafield2'
          click_on I18n.t('projects.samples.show.metadata.update.update')
        end

        assert_text I18n.t('services.samples.metadata.update_fields.key_exists', key: 'metadatafield2')
      end

      test 'user with access level < Maintainer cannot view update action' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
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

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text "#{I18n.t('models.sample.analysis')} 1"
          within('tbody tr:first-child td:last-child') do
            assert_no_text I18n.t('projects.samples.show.metadata.actions.dropdown.update')
          end
        end
      end

      test 'add single new metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          find('input.keyInput').fill_in with: 'metadatafield3'
          find('input.valueInput').fill_in with: 'value3'
          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadatafield3')

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield3_field'

          within %(tr#metadatafield3_field) do
            assert_text 'metadatafield3'
            assert_text 'value3'
          end
        end
      end

      test 'add multiple new metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          all('input.keyInput')[0].fill_in with: 'metadatafield3'
          all('input.valueInput')[0].fill_in with: 'value3'

          all('input.keyInput')[1].fill_in with: 'metadatafield4'
          all('input.valueInput')[1].fill_in with: 'value4'
          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: %w[metadatafield3 metadatafield4].join(', '))

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield3_field'
          assert_selector 'tr#metadatafield4_field'

          within %(tr#metadatafield3_field) do
            assert_text 'metadatafield3'
            assert_text 'value3'
          end

          within %(tr#metadatafield4_field) do
            assert_text 'metadatafield4'
            assert_text 'value4'
          end
        end
      end

      test 'add single existing metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield1_field'

          within %(tr#metadatafield1_field) do
            assert_text 'metadatafield1'
            assert_text 'value1'
          end
        end

        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          find('input.keyInput').fill_in with: 'metadatafield1'
          find('input.valueInput').fill_in with: 'newValue1'
          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('services.samples.metadata.fields.single_all_keys_exist', key: 'metadatafield1')
      end

      test 'add multiple existing metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield1_field'

          within %(tr#metadatafield1_field) do
            assert_text 'metadatafield1'
            assert_text 'value1'
          end

          assert_selector 'tr#metadatafield2_field'

          within %(tr#metadatafield2_field) do
            assert_text 'metadatafield2'
            assert_text 'value2'
          end
        end

        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          all('input.keyInput')[0].fill_in with: 'metadatafield1'
          all('input.valueInput')[0].fill_in with: 'newValue1'

          all('input.keyInput')[1].fill_in with: 'metadatafield2'
          all('input.valueInput')[1].fill_in with: 'newValue2'
          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('services.samples.metadata.fields.multi_all_keys_exist',
                           keys: %w[metadatafield1 metadatafield2].join(', '))
      end

      test 'add both new and existing metadata' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield1_field'
          assert_no_selector 'tr#metadatafield3_field'
          assert_no_text 'metadatafield3'

          within %(tr#metadatafield1_field) do
            assert_text 'metadatafield1'
            assert_text 'value1'
          end
        end
        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          all('input.keyInput')[0].fill_in with: 'metadatafield1'
          all('input.valueInput')[0].fill_in with: 'newValue1'

          all('input.keyInput')[1].fill_in with: 'metadatafield3'
          all('input.valueInput')[1].fill_in with: 'value3'
          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.fields.create.single_success', key: 'metadatafield3')
        assert_text I18n.t('projects.samples.metadata.fields.create.single_key_exists', key: 'metadatafield1')

        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'tr#metadatafield3_field'
          within %(tr#metadatafield3_field) do
            assert_text 'metadatafield3'
            assert_text 'value3'
          end
        end
      end

      test 'add new metadata after deleting fields' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          click_on I18n.t('projects.samples.metadata.form.create_field_button')
          all('input.keyInput')[0].fill_in with: 'metadatafield3'
          all('input.valueInput')[0].fill_in with: 'value3'
          all('input.keyInput')[1].fill_in with: 'metadatafield4'
          all('input.valueInput')[1].fill_in with: 'value4'
          all('input.keyInput')[2].fill_in with: 'metadatafield5'
          all('input.valueInput')[2].fill_in with: 'value5'
          all('input.keyInput')[3].fill_in with: 'metadatafield6'
          all('input.valueInput')[3].fill_in with: 'value6'

          all('button[data-action="projects--samples--metadata--create#removeField"]')[2].click
          all('button[data-action="projects--samples--metadata--create#removeField"]')[1].click

          click_on I18n.t('projects.samples.metadata.form.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.fields.create.multi_success',
                           keys: %w[metadatafield3 metadatafield6].join(', '))

        within %(turbo-frame[id="table-listing"]) do
          assert_no_text 'metadatafield4'
          assert_no_text 'value4'
          assert_no_text 'metadatafield5'
          assert_no_text 'value5'

          assert_selector 'tr#metadatafield3_field'
          within %(tr#metadatafield3_field) do
            assert_text 'metadatafield3'
            assert_text 'value3'
          end

          assert_selector 'tr#metadatafield6_field'
          within %(tr#metadatafield6_field) do
            assert_text 'metadatafield6'
            assert_text 'value6'
          end
        end
      end

      test 'clicking remove button in add modal with one metadata field clears inputs but doesn\'t delete field' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.add_metadata')

        within %(turbo-frame[id="sample_modal"]) do
          assert_selector 'input.keyInput', count: 1
          assert_selector 'input.valueInput', count: 1

          all('button[data-action="projects--samples--metadata--create#removeField"]')[0].click

          assert_selector 'input.keyInput', count: 1
          assert_selector 'input.valueInput', count: 1
        end
      end

      test 'user with access < Maintainer cannot see add metadata' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')
        assert_no_text I18n.t('projects.samples.show.add_metadata')
      end

      test 'delete metadata key added by user' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.delete')
          end
        end

        within('#turbo-confirm[open]') do
          assert_text I18n.t('projects.samples.show.metadata.actions.delete_confirm', deleted_key: 'metadatafield1')
          click_button I18n.t(:'components.confirmation.confirm')
        end

        assert_text I18n.t('projects.samples.metadata.destroy.success', deleted_key: 'metadatafield1')
        within %(turbo-frame[id="table-listing"]) do
          assert_no_text 'metadatafield1'
          assert_no_text 'value1'
        end
      end

      test 'delete metadata key added by anaylsis' do
        @subgroup12aa = groups(:subgroup_twelve_a_a)
        @project31 = projects(:project31)
        @sample34 = samples(:sample34)

        visit namespace_project_sample_url(@subgroup12aa, @project31, @sample34)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          within('tbody tr:first-child td:last-child') do
            click_on I18n.t('projects.samples.show.metadata.actions.dropdown.delete')
          end
        end

        within('#turbo-confirm[open]') do
          assert_text I18n.t('projects.samples.show.metadata.actions.delete_confirm', deleted_key: 'metadatafield1')
          click_button I18n.t(:'components.confirmation.confirm')
        end

        assert_text I18n.t('projects.samples.metadata.destroy.success', deleted_key: 'metadatafield1')
        within %(turbo-frame[id="table-listing"]) do
          assert_no_text 'metadatafield1'
          assert_no_text 'value1'
        end
      end

      test 'delete one metadata key by delete metadata modal' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          find('input#metadatafield1').click
        end

        click_on I18n.t('projects.samples.show.delete_metadata_button')

        within %(turbo-frame[id="sample_modal"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          click_on I18n.t('projects.samples.metadata.deletions.modal.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.deletions.destroy.single_success', deleted_key: 'metadatafield1')
        within %(turbo-frame[id="table-listing"]) do
          assert_no_text 'metadatafield1'
          assert_no_text 'value1'
        end
      end

      test 'delete multiple metadata keys by delete metadata modal' do
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          assert_text 'metadatafield2'
          assert_text 'value2'
          find('input#metadatafield1').click
          find('input#metadatafield2').click
        end

        click_on I18n.t('projects.samples.show.delete_metadata_button')

        within %(turbo-frame[id="sample_modal"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          assert_text 'metadatafield2'
          assert_text 'value2'
          click_on I18n.t('projects.samples.metadata.deletions.modal.submit_button')
        end

        assert_text I18n.t('projects.samples.metadata.deletions.destroy.multi_success',
                           deleted_keys: 'metadatafield1, metadatafield2')
        within %(turbo-frame[id="table-listing"]) do
          assert_no_text 'metadatafield1'
          assert_no_text 'value1'
          assert_no_text 'metadatafield2'
          assert_no_text 'value2'
          assert_text I18n.t('projects.samples.show.no_metadata')
          assert_text I18n.t('projects.samples.show.no_associated_metadata')
        end
      end

      test 'user with access < Maintainer cannot view delete checkboxes, delete action or delete metadata button' do
        sign_in users(:jane_doe)
        visit namespace_project_sample_url(@group12a, @project29, @sample32)

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(turbo-frame[id="table-listing"]) do
          assert_text 'metadatafield1'
          assert_text 'value1'
          assert_text 'metadatafield2'
          assert_text 'value2'
          assert_no_selector 'input[type="checkbox"]'
          assert_no_text I18n.t('projects.samples.show.table_header.action').upcase
        end

        assert_no_selector I18n.t('projects.samples.show.delete_metadata_button')
      end
    end
  end
end
