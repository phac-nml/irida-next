# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class TransfersControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @group = groups(:group_one)
        @project2 = projects(:project2)

        Flipper.enable(:group_samples_transfer)
      end

      test 'should get new if owner' do
        get new_group_samples_transfer_path(@group, format: :turbo_stream)
        assert_response :success
      end

      test 'should get new if maintainer' do
        user = users(:joan_doe)
        login_as user

        get new_group_samples_transfer_path(@group, format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new if access level less than a maintainer' do
        user = users(:ryan_doe)
        login_as user

        get new_group_samples_transfer_path(@group, format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'should enqueue a Groups::Samples::TransferJob' do
        assert_enqueued_jobs 1, only: Groups::Samples::TransferJob do
          post group_samples_transfer_path(@group, format: :turbo_stream),
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
