# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class TransfersControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project1 = projects(:project1)
        @project2 = projects(:project2)
        @namespace = groups(:group_one)
      end

      test 'should get new if owner' do
        get new_namespace_project_samples_transfer_path(@namespace, @project1)
        assert_response :success
      end

      test 'should not get new if non-owner' do
        user = users(:micha_doe)
        login_as user

        get new_namespace_project_samples_transfer_path(@namespace, @project1)
        assert_response :unauthorized
      end

      test 'should create sample transfer for a member that is an owner' do
        post namespace_project_samples_transfer_path(@namespace, @project1, format: :turbo_stream),
             params: {
               new_project_id: @project2.id,
               sample_ids: [@sample1.id, @sample2.id]
             }

        assert_response :success
      end

      test 'should not create sample transfer for a non-member' do
        user = users(:micha_doe)
        login_as user

        post namespace_project_samples_transfer_path(@namespace, @project1),
             params: {
               new_project_id: @project2.id,
               sample_ids: [@sample1.id, @sample2.id]
             }
        assert_response :unauthorized
      end

      test 'should create sample transfer for a member in an ancestor group' do
        namespace = groups(:subgroup_one_group_three)
        project4 = projects(:project4)
        project22 = projects(:project22)
        sample23 = samples(:sample23)
        user = users(:james_doe)
        login_as user

        post namespace_project_samples_transfer_path(namespace, project4, format: :turbo_stream),
             params: {
               new_project_id: project22.id,
               sample_ids: [sample23.id]
             }

        assert_response :success
      end

      test 'should not create sample transfer for a member that is a maintainer' do
        user = users(:joan_doe)
        login_as user

        post namespace_project_samples_transfer_path(@namespace, @project1),
             params: {
               new_project_id: @project2.id,
               sample_ids: [@sample1.id, @sample2.id]
             }
        assert_response :unauthorized
      end

      test 'should not create sample transfer for a member that is a guest' do
        user = users(:ryan_doe)
        login_as user

        post namespace_project_samples_transfer_path(@namespace, @project1),
             params: {
               new_project_id: @project2.id,
               sample_ids: [@sample1.id, @sample2.id]
             }
        assert_response :unauthorized
      end

      test 'should not create sample transfer within the same project' do
        post namespace_project_samples_transfer_path(@namespace, @project1, format: :turbo_stream),
             params: {
               new_project_id: @project1.id,
               sample_ids: [@sample1.id, @sample2.id]
             }

        assert_response :unprocessable_entity
      end

      test 'should do a partial sample transfer' do
        sample3 = samples(:sample3)
        post namespace_project_samples_transfer_path(@namespace, @project1, format: :turbo_stream),
             params: {
               new_project_id: @project2.id,
               sample_ids: [@sample1.id, @sample2.id, sample3.id]
             }

        assert_response :partial_content
      end
    end
  end
end
