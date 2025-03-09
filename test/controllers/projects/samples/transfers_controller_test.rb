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
        get new_namespace_project_samples_transfer_path(@namespace, @project1, format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new if non-owner' do
        user = users(:micha_doe)
        login_as user

        get new_namespace_project_samples_transfer_path(@namespace, @project1)
        assert_response :unauthorized
      end

      test 'should enqueue a Samples::TransferJob' do
        assert_enqueued_jobs 1, only: ::Samples::TransferJob do
          post namespace_project_samples_transfer_path(@namespace, @project1, format: :turbo_stream),
               params: {
                 transfer: {
                   new_project_id: @project2.id,
                   sample_ids: [@sample1.id, @sample2.id]
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end
    end
  end
end
