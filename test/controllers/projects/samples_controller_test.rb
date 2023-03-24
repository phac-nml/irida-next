# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:one)
      @sample4 = samples(:four)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'should get index' do
      get namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_response :success
    end

    test 'should get new' do
      get new_namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_response :success
    end

    test 'should create sample' do
      assert_difference('Sample.count') do
        post namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path),
             params: { sample: {
               description: @sample1.description,
               name: 'New Sample',
               project_id: @sample1.project_id
             } }
      end

      assert_redirected_to namespace_project_sample_url(id: Sample.last.id)
    end

    test 'should not create a sample with wrong parameters' do
      post namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path),
           params: { sample: {
             description: @sample1.description,
             name: '?',
             project_id: @sample1.project_id
           } }

      assert_response :unprocessable_entity
    end

    test 'should show sample' do
      get namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_response :success
    end

    # test 'should not show sample, if it does not belong to the project' do
    #   assert_raises(ActionController::RoutingError) do
    #     get namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample4.id)
    #   end
    # end

    test 'should get edit' do
      get edit_namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path,
                                            id: @sample1.id)
      assert_response :success
    end

    test 'should update sample' do
      patch namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id),
            params: { sample: { description: @sample1.description, name: 'New Sample Name',
                                project_id: @sample1.project_id } }
      assert_redirected_to namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path,
                                                        id: @sample1.id)
    end

    test 'should not update a sample with wrong parameters' do
      patch namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id),
            params: { sample: { description: @sample1.description, name: '?',
                                project_id: @sample1.project_id } }

      assert_response :unprocessable_entity
    end

    test 'should destroy sample' do
      assert_difference('Sample.count', -1) do
        delete namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      end

      assert_redirected_to namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
    end

    test 'should not destroy sample, if it does not belong to the project' do
      delete namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample4.id)

      assert_response :unprocessable_entity
    end
  end
end
