# frozen_string_literal: true

require 'test_helper'

module Samples
  class MetadataControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample23 = samples(:sample23)
      @sample32 = samples(:sample32)
      @project4 = projects(:project4)
      @project29 = projects(:project29)
      @namespace = groups(:subgroup_twelve_a)
    end

    test 'add new metadata' do
      post sample_metadata_path(@sample32),
           params: {
             'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                'metadatafield4' => 'value4' } },
             format: :turbo_stream
           }
      assert_response :ok
    end

    test 'add new metadata where keys exist' do
      post sample_metadata_path(@sample32),
           params: {
             'sample' => { 'create_fields' => { 'metadatafield1' => 'value3',
                                                'metadatafield2' => 'value4' } },
             format: :turbo_stream
           }
      assert_response :unprocessable_entity
    end

    test 'add new metadata where keys both exist and don\'t exist' do
      post sample_metadata_path(@sample32),
           params: {
             'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                'metadatafield1' => 'value4' } },
             format: :turbo_stream
           }
      assert_response :multi_status
    end

    test 'cannot add metadata if not a member with access to the project' do
      sign_in users(:david_doe)
      post sample_metadata_path(@sample32),
           params: {
             'sample' => { 'create_fields' => { 'metadatafield3' => 'value3',
                                                'metadatafield4' => 'value4' } },
             format: :turbo_stream
           }
      assert_response :unauthorized
    end

    test 'update metadata key' do
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield3' },
              'value' => { 'value1' => 'value1' }
            } }, format: :turbo_stream }
      assert_response :ok
    end

    test 'update metadata value' do
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield1' },
              'value' => { 'value1' => 'value2' }
            } }, format: :turbo_stream }
      assert_response :ok
    end

    test 'update metadata key and value' do
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield3' },
              'value' => { 'value1' => 'value2' }
            } }, format: :turbo_stream }
      assert_response :ok
    end

    test 'cannot update metadata key with key that already exists' do
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield2' },
              'value' => { 'value1' => 'value1' }
            } }, format: :turbo_stream }
      assert_response :unprocessable_entity
    end

    test 'update metadata with unchanged metadata' do
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield1' },
              'value' => { 'value1' => 'value1' }
            } }, format: :turbo_stream }
      assert_response :unprocessable_entity
    end

    test 'cannot update sample if not a member with access to the project' do
      sign_in users(:david_doe)
      patch sample_metadata_path(@sample32),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield3' },
              'value' => { 'value1' => 'value3' }
            } }, format: :turbo_stream }
      assert_response :unauthorized
    end

    test 'cannot update metadata key originally added by an analysis' do
      sample34 = samples(:sample34)

      patch sample_metadata_path(sample34),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield3' },
              'value' => { 'value1' => 'value1' }
            } }, format: :turbo_stream }
      assert_response :unprocessable_entity
    end

    test 'cannot update metadata value originally added by an analysis' do
      sample34 = samples(:sample34)

      patch sample_metadata_path(sample34),
            params: { 'sample' => { 'update_field' => {
              'key' => { 'metadatafield1' => 'metadatafield1' },
              'value' => { 'value1' => 'value2' }
            } }, format: :turbo_stream }
      assert_response :unprocessable_entity
    end

    test 'builds correct update params for updating a value' do
      controller = MetadataController.new
      controller.instance_variable_set(:@field, @field)

      expected_params = {
        'update_field' => {
          'key' => { @field => @field },
          'value' => { 'old_value' => 'new_value' }
        }
      }

      assert_equal expected_params,
                   controller.send(:build_update_params, 'old_value', 'new_value')
    end

    test 'renders unchanged field when value does not change' do
      patch sample_metadatum_path(@sample32, 'metadatafield1'),
            params: {
              'value' => 'old_value',
              'original_value' => 'old_value',
              'format' => :turbo_stream
            }
      assert_response :ok
    end

    test 'updates sample metadata with new value' do
      patch sample_metadatum_path(@sample32, 'metadatafield1'),
            params: {
              'value' => 'new_value',
              'original_value' => 'old_value',
              'format' => :turbo_stream
            }
      assert_response :ok
    end
  end
end
