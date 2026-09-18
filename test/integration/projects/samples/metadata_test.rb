# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class MetadataTest < ActionDispatch::IntegrationTest
      setup do
        @sample32 = samples(:sample32)
        @project29 = projects(:project29)
      end

      test 'member with role >= maintainer can view metadata and action buttons' do
        login_as users(:jane_doe)
        get namespace_project_sample_path(@project29.parent, @project29, @sample32, tab: 'metadata')
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
        get namespace_project_sample_path(@project29.parent, @project29, @sample32, tab: 'metadata')
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
        get edit_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
                                                        key: 'metadatafield1',
                                                        value: 'value1')
        assert_response :success

        assert_select 'h1', I18n.t('projects.samples.show.metadata.update.update_metadata')
        assert_select '#sample_update_field_key_input[value=?]', 'metadatafield1'
        assert_select '#sample_update_field_value_input[value=?]', 'value1'
      end

      test 'member with role <= analyst cannot open edit metadata dialog' do
        login_as users(:michelle_doe)
        get edit_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
                                                        key: 'metadatafield1',
                                                        value: 'value1')
        assert_response :unauthorized
      end

      test 'edit metadata request requires key param' do
        login_as users(:jane_doe)
        get edit_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
                                                        value: 'value1')
        assert_response :bad_request
      end

      test 'edit metadata request requires value param' do
        login_as users(:jane_doe)
        get edit_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32, tab: 'metadata',
                                                                                                  key: 'metadatafield1')
        assert_response :bad_request
      end

      test 'member with role >= maintainer can open new metadata dialog' do
        login_as users(:jane_doe)
        get new_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32)
        assert_response :success

        assert_select 'h1', I18n.t('projects.samples.metadata.new_metadata_modal.title')
      end

      test 'member with role <= analyst cannot open new metadata dialog' do
        login_as users(:michelle_doe)
        get new_namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32)
        assert_response :unauthorized
      end

      test 'member with role >= maintainer can delete metadata' do
        login_as users(:jane_doe)
        delete namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
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
        delete namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
                                                      tab: 'metadata',
                                                      sample: { metadata: { invalid_key: '' } },
                                                      format: :turbo_stream)
        assert_response :unprocessable_content
      end

      test 'member with role <= analyst can delete metadata' do
        login_as users(:michelle_doe)
        delete namespace_project_sample_metadata_path(@project29.parent, @project29, @sample32,
                                                      tab: 'metadata',
                                                      sample: { metadata: { metadatafield1: '' } },
                                                      format: :turbo_stream)
        assert_response :unauthorized
      end
    end
  end
end
