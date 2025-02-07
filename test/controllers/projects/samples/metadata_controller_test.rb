# frozen_string_literal: true

require 'test_helper'

module Projects
  class MetadataControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample23 = samples(:sample23)
      @sample32 = samples(:sample32)
      @project4 = projects(:project4)
      @project29 = projects(:project29)
      @namespace = groups(:subgroup_twelve_a)
    end

    test 'delete metadata field added by user' do
      delete namespace_project_sample_metadata_path(@namespace, @project29, @sample32),
             params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
      assert_response :successP

    test 'delete metadata field added by analysis' do
      sample34 = samples(:sample34)
      project31 = projects(:project31)
      namespace = groups(:subgroup_twelve_a_a)

      delete namespace_project_sample_metadata_path(namespace, project31, sample34),
             params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
      assert_response :success
    end

    test 'cannot delete metadata if sample does not belong to the project' do
      delete namespace_project_sample_metadata_path(@namespace, @project4, @sample32),
             params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
      assert_response :not_found
    end

    test 'cannot delete metadata if not a member with access to the project' do
      sign_in users(:david_doe)
      delete namespace_project_sample_metadata_path(@namespace, @project29, @sample32),
             params: { 'sample' => { 'metadata' => { 'metadatafield1' => '' } }, format: :turbo_stream }
      assert_response :unauthorized
    end
  end
end
