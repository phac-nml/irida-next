# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class DestroyTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample23 = samples(:sample23)
        @sample69 = samples(:sample69)
        @group1 = groups(:group_one)
      end

      test 'should destroy single sample at group level' do
        assert_difference('Sample.count', -1) do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.success', count: 1), flash[:success]
        assert_response :redirect
        assert_redirected_to group_samples_path(@group1)
      end

      test 'should not destroy single sample at group level with active workflow executions' do
        Flipper.enable(:prevent_sample_deletions_and_transfers_with_active_workflows)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id]
                 }
               }, as: :turbo_stream
        end
        assert_response :unprocessable_content
        Flipper.disable(:prevent_sample_deletions_and_transfers_with_active_workflows)
      end

      test 'should destroy multiple samples at group level' do
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.success', count: 2), flash[:success]
        assert_response :redirect
        assert_redirected_to group_samples_path(@group1)
      end

      test 'should not destroy multiple samples at group level with active workflow executions' do
        Flipper.enable(:prevent_sample_deletions_and_transfers_with_active_workflows)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end
        assert_response :unprocessable_content
        Flipper.disable(:prevent_sample_deletions_and_transfers_with_active_workflows)
      end

      test 'should not destroy sample, if it does not belong to the group' do
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample69.id]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.no_deleted_samples'), flash[:error]
        assert_response :redirect
        assert_redirected_to group_samples_path(@group1)
      end

      test 'should not destroy sample, if the current user role is < Owner in group' do
        sign_in users(:joan_doe)

        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample23.id]
                 }
               }, as: :turbo_stream
        end

        assert_response :unauthorized
      end

      test 'new destroy with proper authorization from group' do
        get new_samples_deletions_path,
            params: {
              namespace_id: @group1.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :success
      end

      test 'should not get new destroy with role < Owner at group level' do
        sign_in users(:joan_doe)
        get new_samples_deletions_path,
            params: {
              namespace_id: @group1.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :unauthorized
      end

      test 'partially deleting multiple samples at group level' do
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id, 'invalid_sample_id']
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.partial_success', deleted: '2/3'),
                     flash[:success]
        assert_equal I18n.t('samples.deletions.destroy.partial_error', not_deleted: '1/3'),
                     flash[:error]
        assert_response :redirect
        assert_redirected_to group_samples_path(@group1)
      end

      test 'delete no samples at group level' do
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: %w[invalid_sample_id_1 invalid_sample_id_2 invalid_sample_id_3]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.no_deleted_samples'), flash[:error]
        assert_response :redirect
        assert_redirected_to group_samples_path(@group1)
      end

      test 'should not destroy group sample when deletion reason exceeds max length' do
        Flipper.enable(:sample_deletion_reason)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @group1.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id],
                   reason: 'a' * 501
                 }
               }, as: :turbo_stream
        end

        assert_response :unprocessable_content
        assert_match 'Reason is too long', response.body
        assert_match 'form-error-summary', response.body
        Flipper.disable(:sample_deletion_reason)
      end
    end
  end
end
