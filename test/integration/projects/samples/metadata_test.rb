# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class MetadataTest < ActionDispatch::IntegrationTest
      setup do
        @sample32 = samples(:sample32)
        @project29 = projects(:project29)
        @namespace = @project29.parent
      end

      test 'member with role >= maintainer can view metadata and action buttons' do
        login_as users(:jane_doe)
        get namespace_project_sample_path(@namespace, @project29, @sample32, tab: 'metadata')
        assert_response :success

        assert_select 'h1', @sample32.name
        assert_select 'button', I18n.t('projects.samples.metadata.table.add_metadata')
        assert_select 'button', I18n.t('projects.samples.metadata.table.delete_metadata_button')

        assert_select '#metadata-table-body tr', count: 2

        @sample32.metadata.each do |key, value|
          assert_select '#metadata-table-body tr' do
            assert_select "td:first-child input[type='checkbox'][value='#{key}']", count: 1
            assert_select 'td:nth-child(2)', text: key
            assert_select 'td:nth-child(3)', text: value
            assert_select 'td:nth-child(4)', text: User.find(@sample32.metadata_provenance[key]['id']).email
            assert_select 'td:nth-child(5)' do
              assert_select 'time[datetime=?]',
                            Time.iso8601(@sample32.metadata_provenance[key]['updated_at'])
                                .strftime('%Y-%m-%dT%H:%M:%SZ')
            end
            assert_select 'td:last-child', text: "#{I18n.t('common.actions.update')} #{I18n.t('common.actions.delete')}"
          end
        end
      end

      test 'member with role <= analyst can view metadata and but not action buttons' do
        login_as users(:michelle_doe)
        get namespace_project_sample_path(@namespace, @project29, @sample32, tab: 'metadata')
        assert_response :success

        assert_select 'h1', @sample32.name
        assert_select 'button', text: I18n.t('projects.samples.metadata.table.add_metadata'), count: 0
        assert_select 'button', text: I18n.t('projects.samples.metadata.table.delete_metadata_button'), count: 0

        assert_select '#metadata-table-body tr', count: 2

        @sample32.metadata.each do |key, value|
          assert_select '#metadata-table-body tr' do
            assert_select 'td:first-child', text: key
            assert_select 'td:nth-child(2)', text: value
            assert_select 'td:nth-child(3)', text: User.find(@sample32.metadata_provenance[key]['id']).email
            assert_select 'td:last-child' do
              assert_select 'time[datetime=?]',
                            Time.iso8601(@sample32.metadata_provenance[key]['updated_at'])
                                .strftime('%Y-%m-%dT%H:%M:%SZ')
            end
          end
        end
      end

      test 'member with role >= maintainer can open edit metadata dialog' do
        login_as users(:jane_doe)
        get edit_namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                        key: 'metadatafield1',
                                                        value: 'value1')
        assert_response :success

        assert_select 'h1', I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_select '#sample_update_field_key_input[value=?]', 'metadatafield1'
        assert_select '#sample_update_field_value_input[value=?]', 'value1'
      end

      test 'member with role <= analyst cannot open edit metadata dialog' do
        login_as users(:michelle_doe)
        get edit_namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                        key: 'metadatafield1',
                                                        value: 'value1')
        assert_response :unauthorized
      end

      test 'edit metadata request requires key param' do
        login_as users(:jane_doe)
        get edit_namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                        value: 'value1')
        assert_response :bad_request
      end

      test 'edit metadata request requires value param' do
        login_as users(:jane_doe)
        get edit_namespace_project_sample_metadata_path(@namespace, @project29, @sample32, tab: 'metadata',
                                                                                           key: 'metadatafield1')
        assert_response :bad_request
      end

      test 'member with role >= maintainer can open new metadata dialog' do
        login_as users(:jane_doe)
        get new_namespace_project_sample_metadata_path(@namespace, @project29, @sample32)
        assert_response :success

        assert_select 'h1', I18n.t('projects.samples.metadata.new_metadata_modal.title')
      end

      test 'member with role <= analyst cannot open new metadata dialog' do
        login_as users(:michelle_doe)
        get new_namespace_project_sample_metadata_path(@namespace, @project29, @sample32)
        assert_response :unauthorized
      end

      test 'member with role >= maintainer can delete metadata' do
        login_as users(:jane_doe)
        delete namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                      tab: 'metadata',
                                                      sample: { metadata: { metadatafield1: '' } },
                                                      format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.metadata.destroy.success',
                                             deleted_key: 'metadatafield1')}"
            end
          end
        end
      end

      test 'delete metadata with non-existent key' do
        login_as users(:jane_doe)
        delete namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                      tab: 'metadata',
                                                      sample: { metadata: { invalid_key: '' } },
                                                      format: :turbo_stream)
        assert_response :unprocessable_content
      end

      test 'member with role <= analyst cannot delete metadata' do
        login_as users(:michelle_doe)
        delete namespace_project_sample_metadata_path(@namespace, @project29, @sample32,
                                                      tab: 'metadata',
                                                      sample: { metadata: { metadatafield1: '' } },
                                                      format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'member with role >= maintainer can update existing metadata field\'s value' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: 'newmetadatavalue1', id: 'metadatafield1',
                                  format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('samples.editable_cell.update_success')}"
            end
          end
        end

        assert_equal 'newmetadatavalue1', @sample32.reload.metadata['metadatafield1']
      end

      test 'member with role <= analyst cannot update existing metadata field\'s value' do
        login_as users(:michelle_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: 'newmetadatavalue1', id: 'metadatafield1',
                                  format: :turbo_stream)
        assert_response :unauthorized

        assert_equal 'value1', @sample32.reload.metadata['metadatafield1']
      end

      test 'member with role >= maintainer can create new metadata field through update endpoint' do
        login_as users(:jane_doe)
        assert_not @sample32.metadata['newmetadtafield']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: 'newmetadatavalue1', id: 'newmetadatafield',
                                  format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('samples.editable_cell.update_success')}"
            end
          end
        end
        @sample32.reload
        assert_equal 'newmetadatavalue1', @sample32.metadata['newmetadatafield']
      end

      test 'member with role <= analyst cannot create new metadata field through update endpoint' do
        login_as users(:michelle_doe)
        assert_not @sample32.metadata['newmetadatafield']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: 'newmetadatavalue1', id: 'newmetadatafield',
                                  format: :turbo_stream)
        assert_response :unauthorized

        @sample32.reload
        assert_not @sample32.metadata['newmetadatafield']
      end

      test 'cannot create new field through update with empty value' do
        login_as users(:jane_doe)
        assert_not @sample32.metadata['newmetadatafield']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: '', id: 'newmetadatafield',
                                  format: :turbo_stream)
        assert_response :unprocessable_content

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('services.samples.metadata.metadata_fields_not_found',
                                             sample_name: @sample32.name, metadata_fields: 'newmetadatafield')}"
            end
          end
        end
        @sample32.reload
        assert_not @sample32.metadata['newmetadatafield']
      end

      test 'update metadata with already existing value' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: 'value1', id: 'metadatafield1',
                                  format: :turbo_stream)
        assert_response :unprocessable_content

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')}"
            end
          end
        end
        @sample32.reload
        assert_equal 'value1', @sample32.metadata['metadatafield1']
      end

      test 'update metadata with leading/trailing whitespaces does not change metadata' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        put sample_metadatum_path(@sample32,
                                  cell_id: 'a_cell_id', value: '         value1       ', id: 'metadatafield1',
                                  format: :turbo_stream)
        assert_response :unprocessable_content

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')}"
            end
          end
        end
        @sample32.reload
        assert_equal 'value1', @sample32.metadata['metadatafield1']
      end

      test 'bulk_create multiple metadata fields successfully' do
        login_as users(:jane_doe)
        assert_not @sample32.metadata['newmetadatafield1']
        assert_not @sample32.metadata['newmetadatafield2']
        assert_not @sample32.metadata['newmetadatafield3']
        post sample_metadata_path(@sample32,
                                  sample: { create_fields: { newmetadatafield1: 'newvalue1',
                                                             newmetadatafield2: 'newvalue2',
                                                             newmetadatafield3: 'newvalue3' } }, format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.metadata.fields.create.multi_success',
                                             keys: %w[newmetadatafield1 newmetadatafield2
                                                      newmetadatafield3].join(', '))}"
            end
          end
        end

        @sample32.reload
        assert_equal 'newvalue1', @sample32.metadata['newmetadatafield1']
        assert_equal 'newvalue2', @sample32.metadata['newmetadatafield2']
        assert_equal 'newvalue3', @sample32.metadata['newmetadatafield3']
      end

      test 'bulk_create multiple metadata fields multi_status' do
        login_as users(:jane_doe)
        assert_not @sample32.metadata['newmetadatafield1']
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        post sample_metadata_path(@sample32,
                                  sample: { create_fields: { newmetadatafield1: 'newvalue1',
                                                             metadatafield1: 'value2' } }, format: :turbo_stream)
        assert_response :multi_status

        assert_select 'turbo-stream[action="append"][target="flashes"]', count: 2

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template div[role="alert"][data-viral--flash-type-value="success"]' do
            assert_select 'div[id$="-message"]', text: "#{I18n.t('common.statuses.success')}: " \
          "#{I18n.t('projects.samples.metadata.fields.create.single_success',
                    key: 'newmetadatafield1')}"
          end
        end

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template div[role="alert"][data-viral--flash-type-value="error"]' do
            assert_select 'div[id$="-message"]', text: "#{I18n.t('common.statuses.error')}: " \
          "#{I18n.t('projects.samples.metadata.fields.create.single_key_exists',
                    key: 'metadatafield1')}"
          end
        end

        @sample32.reload
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        assert_equal 'newvalue1', @sample32.metadata['newmetadatafield1']
      end

      test 'bulk_create multiple metadata fields that exist' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        assert_equal 'value2', @sample32.metadata['metadatafield2']
        post sample_metadata_path(@sample32,
                                  sample: { create_fields: { metadatafield1: 'newvalue1',
                                                             metadatafield2: 'newvalue2' } }, format: :turbo_stream)
        assert_response :unprocessable_content

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('projects.samples.metadata.fields.create.multi_keys_exists',
                                             keys: %w[metadatafield1 metadatafield2].join(', '))}"
            end
          end
        end

        @sample32.reload
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        assert_equal 'value2', @sample32.metadata['metadatafield2']
      end

      test 'bulk_create with whitespaces' do
        login_as users(:jane_doe)
        assert_not @sample32.metadata['metadata field 1']
        assert_not @sample32.metadata['metadata field 2']
        post sample_metadata_path(@sample32,
                                  sample: { create_fields: { '         metadata   field 1     ' => 'value    1    ',
                                                             'metadata field      2     ' => '     value 2' } },
                                  format: :turbo_stream)
        assert_response :success

        @sample32.reload
        assert_equal 'value 1', @sample32.metadata['metadata field 1']
        assert_equal 'value 2', @sample32.metadata['metadata field 2']
      end

      test 'member with role <= analyst cannot bulk_create' do
        login_as users(:michelle_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        assert_equal 'value2', @sample32.metadata['metadatafield2']
        post sample_metadata_path(@sample32,
                                  sample: { create_fields: { newmetadatafield1: 'newvalue1',
                                                             newmetadatafield2: 'newvalue2' } }, format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'bulk_update new value' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: 'metadatafield1' },
                                                             value: { value1: 'newvalue1' } } },
                                   format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.metadata.fields.update.success')}"
            end
          end
        end

        @sample32.reload
        assert_equal 'newvalue1', @sample32.metadata['metadatafield1']
      end

      test 'bulk_update new metadata field key' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: 'newmetadatafield1' },
                                                             value: { value1: 'value1' } } },
                                   format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.metadata.fields.update.success')}"
            end
          end
        end

        @sample32.reload
        assert_equal 'value1', @sample32.metadata['newmetadatafield1']
        assert_not @sample32.metadata['metadatafield1']
      end

      test 'bulk_update new metadata field key and value' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: 'newmetadatafield1' },
                                                             value: { value1: 'newvalue1' } } },
                                   format: :turbo_stream)
        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.metadata.fields.update.success')}"
            end
          end
        end

        @sample32.reload
        assert_equal 'newvalue1', @sample32.metadata['newmetadatafield1']
        assert_not @sample32.metadata['metadatafield1']
      end

      test 'bulk_update no changes' do
        login_as users(:jane_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: 'metadatafield1' },
                                                             value: { value1: 'value1' } } },
                                   format: :turbo_stream)
        assert_response :unprocessable_content

        @sample32.reload
        assert_equal 'value1', @sample32.metadata['metadatafield1']
      end

      test 'bulk_update cannot overwrite analysis added metadata' do
        sample34 = samples(:sample34)
        login_as users(:john_doe)
        assert_equal 'value1', sample34.metadata['metadatafield1']
        patch sample_metadata_path(sample34,
                                   sample: { update_field: { key: { metadatafield1: 'metadatafield1' },
                                                             value: { value1: 'newvalue1' } } },
                                   format: :turbo_stream)
        assert_response :unprocessable_content

        sample34.reload
        assert_equal 'value1', sample34.metadata['metadatafield1']
      end

      test 'bulk_update with missing value' do
        sample34 = samples(:sample34)
        login_as users(:john_doe)
        assert_equal 'value1', sample34.metadata['metadatafield1']
        patch sample_metadata_path(sample34,
                                   sample: { update_field: { key: { metadatafield1: 'metadatafield1' },
                                                             value: { value1: '' } } },
                                   format: :turbo_stream)
        assert_response :unprocessable_content
        assert_equal 'value1', sample34.reload.metadata['metadatafield1']
        assert_select 'ul#sample_value_error',
                      text: I18n.t('projects.samples.metadata.new_metadata_modal.required_error.value')
      end

      test 'bulk_update with missing key' do
        sample34 = samples(:sample34)
        login_as users(:john_doe)
        assert_equal 'value1', sample34.metadata['metadatafield1']
        patch sample_metadata_path(sample34,
                                   sample: { update_field: { key: { metadatafield1: '' },
                                                             value: { value1: 'newvalue1' } } },
                                   format: :turbo_stream)
        assert_response :unprocessable_content
        assert_equal 'value1', sample34.reload.metadata['metadatafield1']
        assert_select 'ul#sample_key_error',
                      text: I18n.t('projects.samples.metadata.new_metadata_modal.required_error.key')
      end

      test 'bulk_update with whitespcaes' do
        login_as users(:john_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: '   metadata     field   1   ' },
                                                             value: { value1: '    new   value    1   ' } } },
                                   format: :turbo_stream)
        assert_response :success

        @sample32.reload
        assert_not @sample32.metadata['metadatafield1']
        assert_equal 'new value 1', @sample32.metadata['metadata field 1']
      end

      test 'member with role <= analyst cannot bulk_update metadata' do
        login_as users(:michelle_doe)
        assert_equal 'value1', @sample32.metadata['metadatafield1']
        patch sample_metadata_path(@sample32,
                                   sample: { update_field: { key: { metadatafield1: 'newmetadatafield1' },
                                                             value: { value1: 'value1' } } },
                                   format: :turbo_stream)
        assert_response :unauthorized
      end
    end
  end
end
