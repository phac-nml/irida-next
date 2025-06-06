# frozen_string_literal: true

require 'test_helper'

module Samples
  class TransfersControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @namespace = groups(:group_one)
      @project1 = projects(:project1)
      @project2 = projects(:project2)

      Flipper.enable(:group_samples_transfer)
    end

    test 'should get new for group if owner' do
      get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
      assert_response :success
    end

    test 'should get new for group if maintainer' do
      user = users(:joan_doe)
      login_as user

      get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
      assert_response :success
    end

    test 'should not get new for group if access level less than a maintainer' do
      user = users(:ryan_doe)
      login_as user

      get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
      assert_response :unauthorized
    end

    test 'should enqueue a Samples::TransferJo for group' do
      assert_enqueued_jobs 1, only: ::Samples::TransferJob do
        post samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream),
             params: {
               transfer: {
                 new_project_id: @project2.id,
                 sample_ids: [@sample1.id, @sample2.id]
               },
               broadcast_target: 'a_broadcast_target'
             }
      end
    end

    test 'should get new for project if owner' do
      get new_samples_transfer_path(namespace_id: @project1.namespace.id, format: :turbo_stream)
      assert_response :success
    end

    test 'should not get new for project if non-owner' do
      user = users(:micha_doe)
      login_as user

      get new_samples_transfer_path(namespace_id: @project1.namespace.id, format: :turbo_stream)
      assert_response :unauthorized
    end

    test 'should enqueue a Samples::TransferJob for project' do
      assert_enqueued_jobs 1, only: ::Samples::TransferJob do
        post samples_transfer_path(namespace_id: @project1.namespace.id, format: :turbo_stream),
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
