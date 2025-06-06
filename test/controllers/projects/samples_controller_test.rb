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

    test 'should get index where member in parent group' do
      get namespace_project_samples_url(@namespace, @project)
      assert_response :success

      w3c_validate 'Project Samples Page'
    end

    test 'should get index where project is under user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get namespace_project_samples_url(namespace, project)
      assert_response :success
    end

    test 'should get new' do
      get new_namespace_project_sample_url(@namespace, @project)
      assert_response :success
    end

    test 'should search' do
      post search_namespace_project_samples_url(@namespace, @project),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: 'Sample 1' } } } } } },
           as: :turbo_stream
      assert_response :success
    end

    test 'should not search with invalid query' do
      post search_namespace_project_samples_url(@namespace, @project),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: '' } } } } } },
           as: :turbo_stream
      assert_response :unprocessable_entity
    end

    test 'should create sample' do
      assert_difference('Sample.count') do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: 'New Sample'
             } },
             as: :turbo_stream
      end

      assert_redirected_to namespace_project_sample_url(id: Sample.last.id)
    end

    test 'should not create a sample with short sample name parameter' do
      assert_difference -> { Sample.count } => 0,
                        -> { @namespace.reload.samples_count } => 0,
                        -> { @project.reload.samples_count } => 0 do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: '?'
             } }
      end
      assert_response :unprocessable_entity
    end

    test 'should not create a sample with same sample name parameter' do
      assert_difference -> { Sample.count } => 0,
                        -> { @namespace.reload.samples_count } => 0,
                        -> { @project.reload.samples_count } => 0 do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: 'Project 1 Sample 1'
             } }
      end
      assert_response :unprocessable_entity
    end

    test 'should show sample when user is a member of a parent group of the project' do
      get namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should show sample when project is in user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      get namespace_project_sample_url(namespace, project, sample)
      assert_response :success
    end

    test 'should not show sample for a member who does not have access to the project' do
      sign_in users(:david_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      get namespace_project_sample_url(namespace, project, sample)
      assert_response :unauthorized
    end

    test 'should not show sample, if it does not belong to the project' do
      get namespace_project_sample_url(@namespace, @project, @sample23)
      assert_response :not_found
    end

    test 'should get edit' do
      get edit_namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should update sample in which the user is a member in a parent group with a role >= Maintainer' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: 'New Sample Name',
                                project_id: @sample1.project_id } },
            as: :turbo_stream
      assert_redirected_to namespace_project_sample_url(@namespace, @project, @sample1)
    end

    test 'should update sample in which the the project is in the user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      patch namespace_project_sample_url(namespace, project, sample),
            params: { sample: { description: sample.description, name: 'New Sample Name',
                                project_id: sample.project_id } },
            as: :turbo_stream
      assert_redirected_to namespace_project_sample_url(namespace, project, sample)
    end

    test 'should not update a sample with wrong parameters' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: '?',
                                project_id: @sample1.project_id } }

      assert_response :unprocessable_entity
    end

    test 'show sample history listing' do
      @sample1.create_logidze_snapshot!

      get namespace_project_sample_path(@namespace, @project, @sample1, tab: 'history')

      assert_response :success
    end

    test 'view sample history version' do
      @sample1.create_logidze_snapshot!

      get namespace_project_sample_view_history_version_path(@namespace, @project, @sample1, version: 1,
                                                                                             format: :turbo_stream)

      assert_response :success
    end

    test 'should list samples' do
      post list_samples_path(format: :turbo_stream), params: {
        page: 1,
        sample_ids: [@sample1.id],
        list_class: 'sample'
      }
      assert_response :success
    end

    test 'should handle metadata template none' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { metadata_template: 'none' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('input[name="metadata_template"][value="none"]')
    end

    test 'should handle metadata template all' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { metadata_template: 'all' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('input[name="metadata_template"][value="all"]')
    end
  end
end
