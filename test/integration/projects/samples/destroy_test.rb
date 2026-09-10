# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class DestroyTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample22 = samples(:sample22)
        @sample69 = samples(:sample69)
        @project1_namespace = namespaces_project_namespaces(:project1_namespace)
        @project2_namespace = namespaces_project_namespaces(:john_doe_project2_namespace)
      end

      test 'should destroy single sample at project level' do
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -1) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id]
                 }
               }, as: :turbo_stream
        end

        assert_equal I18n.t('samples.deletions.destroy.success', count: 1), flash[:success]
        assert_response :redirect
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
        assert_samples_page(@project1_namespace.project, 2)
      end

      test 'should not destroy single sample at project level with active workflow executions' do
        Flipper.enable(:prevent_sample_deletions_and_transfers_with_active_workflows)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id]
                 }
               }, as: :turbo_stream
        end
        assert_response :unprocessable_content
      ensure
        Flipper.disable(:prevent_sample_deletions_and_transfers_with_active_workflows)
      end

      test 'should destroy multiple samples at project level' do
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.success', count: 2), flash[:success]
        assert_response :redirect
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
        assert_samples_page(@project1_namespace.project, 1)
      end

      test 'should not destroy multiple samples at project level with active workflow executions' do
        Flipper.enable(:prevent_sample_deletions_and_transfers_with_active_workflows)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end
        assert_response :unprocessable_content
      ensure
        Flipper.disable(:prevent_sample_deletions_and_transfers_with_active_workflows)
      end

      test 'should not destroy sample, if it does not belong to the project' do
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample69.id]
                 }
               }, as: :turbo_stream
        end
        assert_equal I18n.t('samples.deletions.destroy.no_deleted_samples'), flash[:error]
        assert_response :redirect
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
      end

      test 'should not destroy sample, if the current user role is < Owner in project' do
        sign_in users(:joan_doe)

        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project2_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample22.id]
                 }
               }, as: :turbo_stream
        end

        assert_response :unauthorized
      end

      test 'new destroy with proper authorization and multiple deletion_type from project' do
        get new_samples_deletions_path,
            params: {
              namespace_id: @project1_namespace.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :success
      end

      test 'new destroy with proper authorization and single deletion_type from project' do
        # remove dialog from samples show page
        get new_samples_deletions_path,
            params: {
              namespace_id: @project1_namespace.id,
              deletion_type: 'single',
              sample_id: @sample1.id
            }, as: :turbo_stream

        assert_response :success
      end

      test 'should not get new destroy multiple deletion_type with role < Owner at project level' do
        sign_in users(:joan_doe)

        get new_samples_deletions_path,
            params: {
              namespace_id: @project2_namespace.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :unauthorized
      end

      test 'should not get new destroy single deletion_type with role < Owner at project level' do
        sign_in users(:joan_doe)

        get new_samples_deletions_path,
            params: {
              namespace_id: @project2_namespace.id,
              deletion_type: 'single',
              sample_id: @sample22
            }, as: :turbo_stream

        assert_response :unauthorized
      end

      test 'partially deleting multiple samples at project level' do
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
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
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
        assert_samples_page(@project1_namespace.project, 1)
      end

      test 'should not destroy project sample when deletion reason exceeds max length' do
        Flipper.enable(:sample_deletion_reason)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
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
      ensure
        Flipper.disable(:sample_deletion_reason)
      end

      test 'destroy sample from sample show page' do
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -1) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id]
                 }
               }, as: :turbo_stream
        end

        assert_equal I18n.t('samples.deletions.destroy.success', count: 1), flash[:success]
        assert_response :redirect
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
        assert_samples_page(@project1_namespace.project, 2)
      end

      test 'destroy sample with reason from sample show page' do
        Flipper.enable(:sample_deletion_reason)
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -1) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'single',
                 deletion: {
                   sample_ids: [@sample1.id],
                   reason: 'cleanup'
                 }
               }, as: :turbo_stream
        end

        assert_equal I18n.t('samples.deletions.destroy.success', count: 1), flash[:success]
        assert_response :redirect
        assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
        assert_samples_page(@project1_namespace.project, 2)
      ensure
        Flipper.disable(:sample_deletion_reason)
      end

      test 'singular description within delete samples dialog' do
        assert_samples_page(@project1_namespace.project, 3)
        get new_samples_deletions_path,
            params: {
              namespace_id: @project1_namespace.id,
              deletion_type: 'single',
              sample_id: @sample1.id
            }, as: :turbo_stream

        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select 'dialog h1', text: I18n.t('samples.deletions.destroy_single_confirmation_dialog.title')
        end
      end

      test 'plural description within delete samples dialog' do
        assert_samples_page(@project1_namespace.project, 3)
        get new_samples_deletions_path,
            params: {
              namespace_id: @project1_namespace.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
        end
      end

      test 'samples listing within delete samples dialog' do
        assert_samples_page(@project1_namespace.project, 3)
        get new_samples_deletions_path,
            params: {
              namespace_id: @project1_namespace.id,
              deletion_type: 'multiple'
            }, as: :turbo_stream

        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select 'turbo-frame#list_selections'
        end
      end

      test 'delete multiple samples' do
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end

        assert_equal I18n.t('samples.deletions.destroy.success', count: 2), flash[:success]
        assert_response :redirect
        assert_samples_page(@project1_namespace.project, 1)
      end

      test 'delete multiple samples with reason' do
        Flipper.enable(:sample_deletion_reason)
        assert_samples_page(@project1_namespace.project, 3)
        assert_difference('Sample.count', -2) do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id],
                   reason: 'cleanup'
                 }
               }, as: :turbo_stream
        end

        assert_equal I18n.t('samples.deletions.destroy.success', count: 2), flash[:success]
        assert_response :redirect
        assert_samples_page(@project1_namespace.project, 1)
      ensure
        Flipper.disable(:sample_deletion_reason)
      end

      test 'prevent sample deletion during active workflow execution' do
        Flipper.enable(:prevent_sample_deletions_and_transfers_with_active_workflows)
        assert_samples_page(@project1_namespace.project, 3)
        assert_no_difference('Sample.count') do
          post samples_deletions_path,
               params: {
                 namespace_id: @project1_namespace.id,
                 deletion_type: 'multiple',
                 deletion: {
                   sample_ids: [@sample1.id, @sample2.id]
                 }
               }, as: :turbo_stream
        end
        assert_response :unprocessable_content
        assert_samples_page(@project1_namespace.project, 3)
      ensure
        Flipper.disable(:prevent_sample_deletions_and_transfers_with_active_workflows)
      end

      private

      def assert_samples_page(project, count)
        namespace = project.namespace.parent || project.namespace
        get namespace_project_samples_path(namespace, project)

        assert_response :success
        assert_select 'tbody#samples-table-body tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def assert_destroy_single_dialog
        assert_select 'dialog h1', text: I18n.t('samples.deletions.destroy_single_confirmation_dialog.title')
        assert_select 'button.dialog--close'
        assert_select 'button', text: I18n.t('common.actions.remove')
      end

      def assert_destroy_multiple_dialog
        assert_select 'dialog h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
        assert_select 'button.dialog--close'
        assert_select 'button', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      end
    end
  end
end
