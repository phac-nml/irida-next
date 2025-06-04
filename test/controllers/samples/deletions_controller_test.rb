# frozen_string_literal: true

require 'test_helper'

module Samples
  class DeletionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample22 = samples(:sample22)
      @sample23 = samples(:sample23)
      @sample69 = samples(:sample69)
      @group1 = groups(:group_one)
      @project1_namespace = namespaces_project_namespaces(:project1_namespace)
      @project2_namespace = namespaces_project_namespaces(:john_doe_project2_namespace)

      Flipper.enable(:group_samples_destroy)
    end

    test 'should destroy single sample at group level' do
      assert_difference('Sample.count', -1) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: [@sample1.id]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.success', count: 1), flash[:success]
      assert_response :redirect
      assert_redirected_to group_samples_path(@group1)
    end

    test 'should destroy multiple samples at group level' do
      assert_difference('Sample.count', -2) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: [@sample1.id, @sample2.id]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.success', count: 2), flash[:success]
      assert_response :redirect
      assert_redirected_to group_samples_path(@group1)
    end

    test 'should destroy single sample at project level' do
      assert_difference('Sample.count', -1) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @project1_namespace.id,
               destroy_samples: {
                 sample_ids: [@sample1.id]
               }
             }, as: :turbo_stream
      end

      assert_equal I18n.t('shared.samples.destroy_samples.success', count: 1), flash[:success]
      assert_response :redirect
      assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
    end

    test 'should destroy multiple samples at project level' do
      assert_difference('Sample.count', -2) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @project1_namespace.id,
               destroy_samples: {
                 sample_ids: [@sample1.id, @sample2.id]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.success', count: 2), flash[:success]
      assert_response :redirect
      assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
    end

    test 'should not destroy sample, if it does not belong to the group' do
      assert_no_difference('Sample.count') do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: [@sample69.id]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.no_deleted_samples'), flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@group1)
    end

    test 'should not destroy sample, if it does not belong to the project' do
      assert_no_difference('Sample.count') do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @project1_namespace.id,
               destroy_samples: {
                 sample_ids: [@sample69.id]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.no_deleted_samples'), flash[:error]
      assert_response :redirect
      assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
    end

    test 'should not destroy sample, if the current user role is < Owner in group' do
      sign_in users(:joan_doe)

      assert_no_difference('Sample.count') do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: [@sample23.id]
               }
             }, as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'should not destroy sample, if the current user role is < Owner in project' do
      sign_in users(:joan_doe)

      assert_no_difference('Sample.count') do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @project2_namespace.id,
               destroy_samples: {
                 sample_ids: [@sample22.id]
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

    test 'should not get new destroy with role < Owner at group level' do
      sign_in users(:joan_doe)
      get new_samples_deletions_path,
          params: {
            namespace_id: @group1.id,
            deletion_type: 'multiple'
          }, as: :turbo_stream

      assert_response :unauthorized
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

    test 'partially deleting multiple samples at group level' do
      assert_difference('Sample.count', -2) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: [@sample1.id, @sample2.id, 'invalid_sample_id']
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.partial_success', deleted: '2/3'),
                   flash[:success]
      assert_equal I18n.t('shared.samples.destroy_samples.partial_error', not_deleted: '1/3'),
                   flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@group1)
    end

    test 'partially deleting multiple samples at project] level' do
      assert_difference('Sample.count', -2) do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @project1_namespace.id,
               destroy_samples: {
                 sample_ids: [@sample1.id, @sample2.id, 'invalid_sample_id']
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.partial_success', deleted: '2/3'),
                   flash[:success]
      assert_equal I18n.t('shared.samples.destroy_samples.partial_error', not_deleted: '1/3'),
                   flash[:error]
      assert_response :redirect
      assert_redirected_to namespace_project_samples_path(@project1_namespace.parent, @project1_namespace.project)
    end

    test 'delete no samples at group level' do
      assert_no_difference('Sample.count') do
        post destroy_samples_samples_deletions_path,
             params: {
               namespace_id: @group1.id,
               destroy_samples: {
                 sample_ids: %w[invalid_sample_id_1 invalid_sample_id_2 invalid_sample_id_3]
               }
             }, as: :turbo_stream
      end
      assert_equal I18n.t('shared.samples.destroy_samples.no_deleted_samples'), flash[:error]
      assert_response :redirect
      assert_redirected_to group_samples_path(@group1)
    end
  end
end
