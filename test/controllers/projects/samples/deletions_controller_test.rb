# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample23 = samples(:sample23)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'should destroy sample' do
      assert_difference('Sample.count', -1) do
        delete namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 sample_id: @sample1.id
               }, as: :turbo_stream
      end
    end

    test 'should not destroy sample, if it does not belong to the project' do
      delete namespace_project_samples_deletion_path(@namespace, @project),
             params: {
               sample_id: @sample23.id
             }, as: :turbo_stream

      assert_response :not_found
    end

    test 'should not destroy sample, if the current user is not allowed to modify the project' do
      sign_in users(:ryan_doe)

      assert_no_difference('Sample.count') do
        delete namespace_project_samples_deletion_path(@namespace, @project, @sample1)
      end

      assert_response :unauthorized
    end

    test 'new_destroy_multiple with proper authorization' do
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            'deletion type' => 'multiple'
          }

      assert_response :success
    end

    test 'new_destroy_multiple without proper authorization' do
      sign_in users(:jane_doe)
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            'deletion type' => 'multiple'
          }

      assert_response :unauthorized
    end

    test 'successfully deleting multiple samples' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)
      delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
             params: {
               multiple_deletion: {
                 sample_ids: [@sample1.id, sample2.id, sample30.id]
               }
             }, as: :turbo_stream

      assert_response :success
    end

    test 'partially deleting multiple samples' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)
      delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
             params: {
               multiple_deletion: {
                 sample_ids: [@sample1.id, sample2.id, sample30.id, 'invalid_sample_id']
               }
             }, as: :turbo_stream

      assert_response :multi_status
    end

    test 'deleting no samples in destroy_multiple ' do
      delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
             params: {
               multiple_deletion: {
                 sample_ids: %w[invalid_sample_id_1 invalid_sample_id_2 invalid_sample_id_3]
               }
             }, as: :turbo_stream

      assert_response :unprocessable_entity
    end
  end
end
