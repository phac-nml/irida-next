# frozen_string_literal: true

require 'test_helper'

module Groups
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample23 = samples(:sample23)
      @namespace = groups(:group_one)
    end

    test 'should destroy samples' do
      assert_difference('Sample.count', -2) do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_multiple.success'), flash[:success]
      assert_response :redirect
      assert_redirected_to group_samples_path(@namespace)
    end

    test 'should not destroy sample, if it does not belong to the group' do
      assert_no_difference('Sample.count') do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: [@sample23.id]
                 }
               }, as: :turbo_stream
      end
      assert_response :redirect
    end

    test 'should not destroy sample, if the current user is not allowed to modify the project' do
      sign_in users(:ryan_doe)

      assert_no_difference('Sample.count') do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: [@sample23.id]
                 }
               }
      end

      assert_response :unauthorized
    end

    test 'new destroy with multiple type with proper authorization' do
      get new_group_samples_deletion_path(@namespace)

      assert_response :success
    end

    test 'new destroy with multiple type without proper authorization' do
      sign_in users(:jane_doe)
      get new_group_samples_deletion_path(@namespace)

      assert_response :unauthorized
    end

    test 'partially deleting multiple samples' do
      assert_difference('Sample.count', -2) do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: [@sample1.id, @sample2.id, 'invalid_sample_id']
                 }
               }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_multiple.partial_success', deleted: '2/3'),
                   flash[:success]
      assert_equal I18n.t('shared.samples.destroy_multiple.partial_error', not_deleted: '1/3'),
                   flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@namespace)
    end

    test 'deleting no samples in destroy_multiple' do
      assert_no_difference('Sample.count') do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: %w[invalid_sample_id_1 invalid_sample_id_2 invalid_sample_id_3]
                 }
               }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_multiple.no_deleted_samples'), flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@namespace)
    end

    test 'deleting no samples in destroy_multiple with valid sample ids but do not belong to group' do
      sample65 = samples(:sample65)
      sample66 = samples(:sample66)

      assert_no_difference('Sample.count') do
        delete group_samples_deletion_path(@namespace),
               params: {
                 destroy_samples: {
                   sample_ids: [sample65.id, sample66.id]
                 }
               }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_multiple.no_deleted_samples'), flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@namespace)
    end
  end
end
