# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Metadata
      class DeletionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_in users(:john_doe)
          @sample23 = samples(:sample23)
          @sample32 = samples(:sample32)
          @project4 = projects(:project4)
          @project29 = projects(:project29)
          @namespace = groups(:subgroup_twelve_a)
        end

        test 'delete one metadata key' do
          delete namespace_project_sample_metadata_deletion_path(@namespace, @project29, @sample32),
                 params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
          assert_response :success
        end

        test 'delete multiple metadata keys at once' do
          delete namespace_project_sample_metadata_deletion_path(@namespace, @project29, @sample32),
                 params: { 'sample' => { 'metadata' => { 'metadatafield1' => '', 'metadatafield2' => '' } },
                           format: :turbo_stream }
          assert_response :success
        end

        test 'cannot delete metadata if sample does not belong to the project' do
          delete namespace_project_sample_metadata_deletion_path(@namespace, @project4, @sample32),
                 params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
          assert_response :not_found
        end

        test 'cannot delete metadata if not a member with access to the project' do
          sign_in users(:david_doe)
          delete namespace_project_sample_metadata_deletion_path(@namespace, @project29, @sample32),
                 params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
          assert_response :unauthorized
        end
      end
    end
  end
end
