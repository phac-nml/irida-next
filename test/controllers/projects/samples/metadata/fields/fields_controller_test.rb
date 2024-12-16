# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Metadata
      module Fields
        class FieldsControllerTest < ActionDispatch::IntegrationTest
          setup do
            sign_in users(:john_doe)
            @sample23 = samples(:sample23)
            @sample32 = samples(:sample32)
            @project4 = projects(:project4)
            @project29 = projects(:project29)
            @namespace = groups(:subgroup_twelve_a)
          end

          test 'add new metadata' do
            post namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                 params: {
                   'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                      'metadatafield4' => 'value4' } },
                   format: :turbo_stream
                 }
            assert_response :ok
          end

          test 'add new metadata where keys exist' do
            post namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                 params: {
                   'sample' => { 'create_fields' => { 'metadatafield1' => 'value3',
                                                      'metadatafield2' => 'value4' } },
                   format: :turbo_stream
                 }
            assert_response :unprocessable_entity
          end

          test 'add new metadata where keys both exist and don\'t exist' do
            post namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                 params: {
                   'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                      'metadatafield1' => 'value4' } },
                   format: :turbo_stream
                 }
            assert_response :multi_status
          end

          test 'cannot add metadata if sample does not belong to the project' do
            post namespace_project_sample_metadata_field_path(@namespace, @project4, @sample32),
                 params: {
                   'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                      'metadatafield4' => 'value4' } },
                   format: :turbo_stream
                 }
            assert_response :not_found
          end

          test 'cannot add metadata if not a member with access to the project' do
            sign_in users(:david_doe)
            post namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                 params: {
                   'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                      'metadatafield4' => 'value4' } },
                   format: :turbo_stream
                 }
            assert_response :unauthorized
          end

          test 'update metadata key' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'update metadata value' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield1' },
                    'value' => { 'value1' => 'value2' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'update metadata key and value' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value2' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'cannot update metadata key with key that already exists' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield2' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'update metadata with unchanged metadata' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield1' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'cannot update metadata if sample does not belong to the project' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project4, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value3' }
                  } }, format: :turbo_stream }
            assert_response :not_found
          end

          test 'cannot update sample if not a member with access to the project' do
            sign_in users(:david_doe)
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value3' }
                  } }, format: :turbo_stream }
            assert_response :unauthorized
          end

          test 'cannot update metadata key originally added by an analysis' do
            sample34 = samples(:sample34)
            project31 = projects(:project31)
            namespace = groups(:subgroup_twelve_a_a)

            patch namespace_project_sample_metadata_field_path(namespace, project31, sample34),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'cannot update metadata value originally added by an analysis' do
            sample34 = samples(:sample34)
            project31 = projects(:project31)
            namespace = groups(:subgroup_twelve_a_a)

            patch namespace_project_sample_metadata_field_path(namespace, project31, sample34),
                  params: { 'sample' => { 'update_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield1' },
                    'value' => { 'value1' => 'value2' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'check to edit a metadata field' do
            get editable_namespace_project_sample_metadata_field_path(
              @namespace, @project29, @sample32
            ), params: {
              'field' => 'metadatafield1',
              'format' => :turbo_stream
            }
            assert_response :ok
          end

          test 'renders unchanged field when value does not change' do
            patch update_value_namespace_project_sample_metadata_field_path(
              @namespace, @project29, @sample32
            ),
                  params: {
                    'field' => 'metadatafield1',
                    'value' => 'old_value',
                    'original_value' => 'old_value',
                    'format' => :turbo_stream
                  }
            assert_response :ok
          end

          test 'updates sample metadata with new value' do
            patch update_value_namespace_project_sample_metadata_field_path(
              @namespace, @project29, @sample32
            ),
                  params: {
                    'field' => 'metadatafield1',
                    'value' => 'new_value',
                    'original_value' => 'old_value',
                    'format' => :turbo_stream
                  }
            assert_response :ok
          end
        end
      end
    end
  end
end
