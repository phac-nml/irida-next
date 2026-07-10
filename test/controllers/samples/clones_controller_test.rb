# frozen_string_literal: true

require 'test_helper'

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

    test 'should enqueue a Samples::CloneJob from project' do
      assert_enqueued_jobs 1, only: Samples::CloneJob do
        post samples_clone_path,
             params: {
               namespace_id: @project.namespace.id,
               clone: {
                 new_project_id: @new_project.id,
                 sample_ids: [@sample1.id, @sample2.id]
               },
               broadcast_target: 'a_broadcast_target'
             }, as: :turbo_stream
      end
    end

    test 'should enqueue a Samples::CloneJob from group' do
      assert_enqueued_jobs 1, only: Samples::CloneJob do
        post samples_clone_path,
             params: {
               namespace_id: @namespace.id,
               clone: {
                 new_project_id: @new_project.id,
                 sample_ids: [@sample1.id, @sample2.id]
               },
               broadcast_target: 'a_broadcast_target'
             }, as: :turbo_stream
      end
    end

    test 'new with proper authorization from project' do
      get new_samples_clone_path, params: { namespace_id: @project.namespace.id }, as: :turbo_stream

      assert_response :success
    end

    test 'new with proper authorization from group' do
      get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream

      assert_response :success
    end

    test 'new without proper authorization from project' do
      sign_in users(:ryan_doe)
      get new_samples_clone_path, params: { namespace_id: @project.namespace.id }, as: :turbo_stream

      assert_response :unauthorized
    end

    test 'new without proper authorization from group' do
      sign_in users(:ryan_doe)
      get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream

      assert_response :unauthorized
    end
  end
end
