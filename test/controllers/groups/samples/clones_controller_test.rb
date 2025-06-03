# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class ClonesControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @new_project = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)

        Flipper.enable(:group_samples_clone)
      end

      test 'should enqueue a Groups::Samples::CloneJob' do
        assert_enqueued_jobs 1, only: Groups::Samples::CloneJob do
          post group_samples_clone_path(@namespace, format: :turbo_stream),
               params: {
                 clone: {
                   new_project_id: @new_project.id,
                   sample_ids: [@sample1.id, @sample2.id]
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end

      test 'new with proper authorization' do
        get new_group_samples_clone_path(@namespace), as: :turbo_stream

        assert_response :success
      end

      test 'new without proper authorization' do
        sign_in users(:ryan_doe)
        get new_group_samples_clone_path(@namespace), as: :turbo_stream

        assert_response :unauthorized
      end
    end
  end
end
