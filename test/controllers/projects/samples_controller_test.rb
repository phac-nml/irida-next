# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample = samples(:one)
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
               description: @sample.description,
               name: 'New Sample',
               project_id: @sample.project_id
             } }
      end

      assert_redirected_to namespace_project_sample_url(id: Sample.last.id)
    end

    test 'should show sample' do
      get namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      assert_response :success
    end

    test 'should get edit' do
      get edit_namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path,
                                            id: @sample.id)
      assert_response :success
    end

    test 'should update sample' do
      patch namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id),
            params: { sample: { description: @sample.description, name: 'New Sample Name',
                                project_id: @sample.project_id } }
      assert_redirected_to namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path,
                                                        id: @sample.id)
    end

    test 'should destroy sample' do
      assert_difference('Sample.count', -1) do
        delete namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      end

      assert_redirected_to namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
    end
  end
end
