# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class EditTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project1_namespace = namespaces_project_namespaces(:project1_namespace)
        @project = projects(:project1)
        @namespace = groups(:group_one)
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

        assert_response :unprocessable_content
      end

      test 'should not update a sample with wrong parameters via turbo stream' do
        patch namespace_project_sample_url(@namespace, @project, @sample1),
              params: { sample: { description: @sample1.description, name: '?',
                                  project_id: @sample1.project_id } },
              as: :turbo_stream

        assert_response :unprocessable_content
      end

      test 'edit sample' do
        project = @project1_namespace.project

        # Update sample
        patch namespace_project_sample_path(@project1_namespace.parent, project, @sample1),
              params: {
                sample: {
                  name: 'New Sample Name',
                  description: 'A new description'
                }
              }

        # Verify redirect to sample show page
        assert_response :redirect
        assert_redirected_to namespace_project_sample_path(@project1_namespace.parent, project, @sample1)

        # Follow redirect and verify sample updates
        follow_redirect!
        assert_response :success
        assert_select 'h1', text: 'New Sample Name'
        assert_select 'p', text: 'A new description'
      end

      test 'edit sample with blank name' do
        project = @project1_namespace.project

        # Update sample with blank name
        patch namespace_project_sample_path(@project1_namespace.parent, project, @sample1),
              params: {
                sample: {
                  name: '',
                  description: 'A new description'
                }
              }

        # Verify validation errors are displayed
        assert_response :unprocessable_content
        assert_error_text "Name can't be blank"
        assert_error_text 'Name is too short (minimum is 3 characters)'
      end

      test 'edit sample to match existing sample' do
        project = @project1_namespace.project

        # Update sample to match existing sample name
        patch namespace_project_sample_path(@project1_namespace.parent, project, @sample1),
              params: {
                sample: {
                  name: @sample2.name,
                  description: 'A new description'
                }
              }

        # Verify validation error is displayed
        assert_response :unprocessable_content
        assert_error_text 'Name has already been taken'
      end

      private

      def assert_error_text(message)
        assert_select '[data-controller="form-error-summary"]' do
          assert_select 'li', text: /#{Regexp.escape(message)}/
        end
      end
    end
  end
end
