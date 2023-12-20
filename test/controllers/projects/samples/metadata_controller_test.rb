# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class MetadataControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @sample1 = samples(:sample1)
        @sample23 = samples(:sample23)
        @project1 = projects(:project1)
        @project2 = projects(:project2)
        @namespace = groups(:group_one)
      end

      test 'updating metadata with no analysis_id' do
        patch namespace_project_sample_metadata_path(@namespace, @project1, @sample1),
              params: { metadata: { metadata: { key1: 'value1' } }, format: :turbo_stream }
        assert_redirected_to namespace_project_path(@namespace, @project1)
      end
      test 'updating metadata with analysis_id' do
        patch namespace_project_sample_metadata_path(@namespace, @project1, @sample1),
              params: { metadata: { metadata: { key1: 'value1' }, analysis_id: 1 }, format: :turbo_stream }
        assert_redirected_to namespace_project_path(@namespace, @project1)
      end

      test 'updating metadata to delete field value from sample' do
        patch namespace_project_sample_metadata_path(@namespace, @project1, @sample1),
              params: { metadata: { metadata: { key1: '' } }, format: :turbo_stream }
        assert_redirected_to namespace_project_path(@namespace, @project1)
      end

      test 'cannot update sample, if it does not belong to the project' do
        patch namespace_project_sample_metadata_path(@namespace, @project1, @sample23),
              params: { metadata: { metadata: { key1: 'value1' } }, format: :turbo_stream }
        assert_response :not_found
      end

      test 'cannot update sample if not a member with access to the project' do
        sign_in users(:david_doe)
        namespace = namespaces_user_namespaces(:john_doe_namespace)
        project = projects(:john_doe_project2)
        sample = samples(:sample24)

        patch namespace_project_sample_metadata_path(namespace, project, sample),
              params: { metadata: { metadata: { key1: 'value1' } }, format: :turbo_stream }
        assert_response :unauthorized
      end
    end
  end
end
