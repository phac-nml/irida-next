# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample23 = samples(:sample23)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'should get index' do
      get namespace_project_samples_url(@namespace, @project)
      assert_response :success
    end

    test 'should get new' do
      get new_namespace_project_sample_url(@namespace, @project)
      assert_response :success
    end

    test 'should create sample' do
      assert_difference('Sample.count') do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: 'New Sample'
             } }
      end

      assert_redirected_to namespace_project_sample_url(id: Sample.last.id)
    end

    test 'should not create a sample with wrong parameters' do
      post namespace_project_samples_url(@namespace, @project),
           params: { sample: {
             description: @sample1.description,
             name: '?'
           } }

      assert_response :unprocessable_entity
    end

    test 'should show sample' do
      get namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should not show sample, if it does not belong to the project' do
      get namespace_project_sample_url(@namespace, @project, @sample23)
      assert_response :not_found
    end

    test 'should get edit' do
      get edit_namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should update sample' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: 'New Sample Name',
                                project_id: @sample1.project_id } }
      assert_redirected_to namespace_project_sample_url(@namespace, @project, @sample1)
    end

    test 'should not update a sample with wrong parameters' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: '?',
                                project_id: @sample1.project_id } }

      assert_response :unprocessable_entity
    end

    test 'should destroy sample' do
      assert_difference('Sample.count', -1) do
        delete namespace_project_sample_url(@namespace, @project, @sample1)
      end

      assert_redirected_to namespace_project_samples_url(@namespace, @project)
    end

    test 'should not destroy sample, if it does not belong to the project' do
      delete namespace_project_sample_url(@namespace, @project, @sample23)

      assert_response :not_found
    end

    test 'should not destroy sample, if the current user is not allowed to modify the project' do
      sign_in users(:ryan_doe)

      assert_no_difference('Sample.count') do
        delete namespace_project_sample_url(@namespace, @project, @sample1)
      end

      assert_response :unauthorized
    end
  end
end
