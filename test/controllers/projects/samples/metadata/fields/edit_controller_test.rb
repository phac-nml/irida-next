# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Metadata
      module Fields
        class EditControllerTest < ActionDispatch::IntegrationTest
          setup do
            sign_in users(:john_doe)
            @sample23 = samples(:sample23)
            @sample32 = samples(:sample32)
            @project4 = projects(:project4)
            @project29 = projects(:project29)
            @namespace = groups(:subgroup_twelve_a)
          end

          test 'update metadata key' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'update metadata value' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield1' },
                    'value' => { 'value1' => 'value2' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'update metadata key and value' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value2' }
                  } }, format: :turbo_stream }
            assert_response :ok
          end

          test 'cannot update metadata key with key that already exists' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield2' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'update metadata with unchanged metadata' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield1' },
                    'value' => { 'value1' => 'value1' }
                  } }, format: :turbo_stream }
            assert_response :unprocessable_entity
          end

          test 'cannot edit metadata if sample does not belong to the project' do
            patch namespace_project_sample_metadata_field_path(@namespace, @project4, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value3' }
                  } }, format: :turbo_stream }
            assert_response :not_found
          end

          test 'cannot update sample if not a member with access to the project' do
            sign_in users(:david_doe)
            patch namespace_project_sample_metadata_field_path(@namespace, @project29, @sample32),
                  params: { 'sample' => { 'edit_field' => {
                    'key' => { 'metadatafield1' => 'metadatafield3' },
                    'value' => { 'value1' => 'value3' }
                  } }, format: :turbo_stream }
            assert_response :unauthorized
          end
        end
      end
    end
  end
end
