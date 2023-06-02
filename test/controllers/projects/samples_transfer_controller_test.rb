# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesTransferControllerTest < ActionDispatch::IntegrationTest
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

    test 'should create sample transfer for a member that is an owner' do
      post namespace_project_samples_transfer_index_path(@namespace, @project1),
           params: { sample_transfer: {
             project_id: @project2.id,
             sample_ids: [JSON.generate([@sample1.id, @sample2.id])]
           } }

      assert_redirected_to namespace_project_samples_path
    end

    test 'should not create sample transfer for a member that is a maintainer' do
      user = users(:joan_doe)
      login_as user

      post namespace_project_samples_transfer_index_path(@namespace, @project1),
           params: { sample_transfer: {
             project_id: @project2.id,
             sample_ids: [JSON.generate([@sample1.id, @sample2.id])]
           } }
      assert_response :unauthorized
    end

    test 'should not create sample transfer for a member that is a guest' do
      user = users(:ryan_doe)
      login_as user

      post namespace_project_samples_transfer_index_path(@namespace, @project1),
           params: { sample_transfer: {
             project_id: @project2.id,
             sample_ids: [JSON.generate([@sample1.id, @sample2.id])]
           } }
      assert_response :unauthorized
    end

    test 'should not create sample transfer within the same project' do
      post namespace_project_samples_transfer_index_path(@namespace, @project1),
           params: { sample_transfer: {
             project_id: @project1.id,
             sample_ids: [JSON.generate([@sample1.id, @sample2.id])]
           } }

      assert_response :unprocessable_entity
    end
  end
end
