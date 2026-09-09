# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class CloneTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @project2 = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
      end

      test 'new with proper authorization from group' do
        get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream
        assert_response :success
      end

      test 'new without proper authorization from group' do
        sign_in users(:ryan_doe)
        get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream
        assert_response :unauthorized
      end

      test 'should enqueue a Samples::CloneJob from group' do
        assert_enqueued_jobs 1, only: ::Samples::CloneJob do
          post_clone(namespace_id: @namespace.id, sample_ids: [@sample1.id, @sample2.id],
                     destination: @project2)
        end
      end

      private

      def post_clone(namespace_id: @namespace.id, sample_ids: @project.samples.ids, destination: @project2)
        post samples_clone_path,
             params: {
               namespace_id:,
               clone: {
                 new_project_id: destination.id,
                 sample_ids:
               },
               broadcast_target: 'a_broadcast_target'
             }, as: :turbo_stream
      end
    end
  end
end
