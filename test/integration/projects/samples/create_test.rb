# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class CreateTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project1_namespace = namespaces_project_namespaces(:project1_namespace)
        @project = projects(:project1)
        @namespace = groups(:group_one)
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
        assert_response :unprocessable_content
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
        assert_response :unprocessable_content
      end

      test 'create sample' do
        # Verify initial sample count
        project = @project1_namespace.project
        assert_equal 3, project.samples.count

        # Create new sample
        assert_difference('Sample.count', 1) do
          post namespace_project_samples_path(@project1_namespace.parent, project),
               params: {
                 sample: {
                   name: 'New Name',
                   description: 'A sample description'
                 }
               }
        end

        # Verify redirect to sample show page
        assert_response :redirect
        new_sample = Sample.last
        assert_redirected_to namespace_project_sample_path(@project1_namespace.parent, project, new_sample)

        # Follow redirect and verify sample details
        follow_redirect!
        assert_response :success
        assert_select 'h1', text: 'New Name'
        assert_select 'p', text: 'A sample description'
      end

      test 'create sample with missing name' do
        project = @project1_namespace.project

        # Create sample with missing name
        assert_no_difference('Sample.count') do
          post namespace_project_samples_path(@project1_namespace.parent, project),
               params: {
                 sample: {
                   name: '',
                   description: 'A sample description'
                 }
               }
        end

        # Verify validation errors are displayed
        assert_response :unprocessable_content
        assert_error_text "Name can't be blank"
        assert_error_text 'Name is too short (minimum is 3 characters)'
      end

      test 'create sample with existing name' do
        project = @project1_namespace.project

        # Create sample with existing name
        assert_no_difference('Sample.count') do
          post namespace_project_samples_path(@project1_namespace.parent, project),
               params: {
                 sample: {
                   name: @sample1.name,
                   description: 'A sample description'
                 }
               }
        end

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
