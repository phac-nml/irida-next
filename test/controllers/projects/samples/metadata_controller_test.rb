# frozen_string_literal: true

require 'test_helper'

module Projects
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

      test 'update metadata key' do
        patch namespace_project_sample_metadata_path(@namespace, @project29, @sample32),
              params: { 'sample' => { 'metadata' => { 'metadatafield1' => '', 'metadatafield3' => 'value1' } },
                        format: :turbo_stream }
        assert_response :ok
      end

      test 'update metadata value' do
        patch namespace_project_sample_metadata_path(@namespace, @project29, @sample32),
              params: { 'sample' => { 'metadata' => { 'metadatafield1' => 'value3' } },
                        format: :turbo_stream }
        assert_response :ok
      end

      test 'cannot update sample, if it does not belong to the project' do
        patch namespace_project_sample_metadata_path(@namespace, @project4, @sample32),
              params: { 'sample' => { 'metadata' => { 'metadatafield1' => 'value3' } },
                        format: :turbo_stream }
        assert_response :not_found
      end

      test 'cannot update sample if not a member with access to the project' do
        sign_in users(:david_doe)
        patch namespace_project_sample_metadata_path(@namespace, @project29, @sample32),
              params: { 'sample' => { 'metadata' => { 'metadatafield1' => 'value3' } },
                        format: :turbo_stream }
        assert_response :unauthorized
      end
    end
  end
end
