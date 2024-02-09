# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class ClonesControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @new_project = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
      end

      test 'not clone samples with empty params' do
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: nil,
                 sample_ids: nil
               }
             }
        assert_response :unprocessable_entity
      end

      test 'not clone samples with no sample ids' do
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: @new_project.id,
                 sample_ids: []
               }
             }, as: :json
        assert_response :unprocessable_entity
      end

      test 'not clone samples with into same project' do
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: @project.id,
                 sample_ids: [@sample1.id, @sample2.id]
               }
             }
        assert_response :unprocessable_entity
      end

      test 'not clone samples with same sample name' do
        new_project = projects(:project34)
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: new_project.id,
                 sample_ids: [@sample2.id]
               }
             }
        assert_response :unprocessable_entity
      end

      test 'clone samples with permission' do
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: @new_project.id,
                 sample_ids: [@sample1.id, @sample2.id]
               }
             }

        assert_response :success
      end

      test 'not clone samples without permission' do
        new_project = projects(:project33)
        post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
             params: {
               clone: {
                 new_project_id: new_project.id,
                 sample_ids: [@sample1.id, @sample2.id]
               }
             }
        assert_response :unauthorized
      end
    end
  end
end
