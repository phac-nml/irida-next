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
      assert_no_difference('Sample.count') do
        delete namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 sample_id: @sample23.id
               }, as: :turbo_stream
      end
      assert_response :not_found
    end

    test 'should not destroy sample, if the current user is not allowed to modify the project' do
      sign_in users(:ryan_doe)

      assert_no_difference('Sample.count') do
        delete namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 deletion_type: 'single',
                 sample_id: @sample1.id
               }
      end

      assert_response :unauthorized
    end

    test 'new destroy with single type with proper authorization' do
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            deletion_type: 'single',
            sample_id: @sample1.id
          }

      assert_response :success
    end

    test 'new destroy with single type without proper authorization' do
      sign_in users(:jane_doe)
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            deletion_type: 'single',
            sample_id: @sample1.id
          }

      assert_response :unauthorized
    end

    test 'new destroy with multiple type with proper authorization' do
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            deletion_type: 'multiple'
          }

      assert_response :success
    end

    test 'new destroy with multiple type without proper authorization' do
      sign_in users(:jane_doe)
      get new_namespace_project_samples_deletion_path(@namespace, @project),
          params: {
            deletion_type: 'multiple'
          }

      assert_response :unauthorized
    end

    test 'successfully deleting multiple samples' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)
      assert_difference('Sample.count', -3) do
        delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 multiple_deletion: {
                   sample_ids: [@sample1.id, sample2.id, sample30.id]
                 }
               }, as: :turbo_stream
      end
      assert_response :success
    end

    test 'partially deleting multiple samples' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)
      assert_difference('Sample.count', -3) do
        delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 multiple_deletion: {
                   sample_ids: [@sample1.id, sample2.id, sample30.id, 'invalid_sample_id']
                 }
               }, as: :turbo_stream
      end
      assert_response :multi_status
    end

    test 'deleting no samples in destroy_multiple' do
      assert_no_difference('Sample.count') do
        delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 multiple_deletion: {
                   sample_ids: %w[invalid_sample_id_1 invalid_sample_id_2 invalid_sample_id_3]
                 }
               }, as: :turbo_stream
      end
      assert_response :unprocessable_entity
    end

    test 'deleting no samples in destroy_multiple with valid sample ids but do not belong to project' do
      sample4 = samples(:sample4)
      sample5 = samples(:sample5)
      sample6 = samples(:sample6)

      assert_no_difference('Sample.count') do
        delete destroy_multiple_namespace_project_samples_deletion_path(@namespace, @project),
               params: {
                 multiple_deletion: {
                   sample_ids: [sample4.id, sample5.id, sample6.id]
                 }
               }, as: :turbo_stream
      end
      assert_response :unprocessable_entity
    end
  end
end
