# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class RollTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
        @sample32 = samples(:sample32)
        @project = projects(:project1)
        @project2 = projects(:project2)
        @project29 = projects(:project29)
        @namespace = groups(:group_one)
        @subgroup12a = groups(:subgroup_twelve_a)
      end

      test 'User with role >= Analyst sees select and deselect buttons for samples table' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_selection_controls(@sample1, present: true)
      end

      test 'User with role < Analyst does not see select and deselect buttons for samples table' do
        sign_in users(:ryan_doe)
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_selection_controls(@sample1, present: false)
      end

      test 'User with role >= Analyst sees sample table checkboxes' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_selection_controls(@sample1, present: true)
      end

      test 'User with role < Analyst does not see sample table checkboxes' do
        sign_in users(:ryan_doe)
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_selection_controls(@sample1, present: false)
      end

      test 'User with role >= Analyst sees workflow execution link' do
        user = users(:james_doe)
        sign_in user
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_workflow_execution_link(present: true, locale: user.locale)
      end

      test 'User with role < Analyst does not see workflow execution link' do
        user = users(:ryan_doe)
        sign_in user
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_workflow_execution_link(present: false, locale: user.locale)
      end

      test 'User with role >= Analyst sees sample actions dropdown' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: @user.locale)
      end

      test 'User with role < Analyst does not see sample actions dropdown' do
        sign_in users(:ryan_doe)
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present: false, locale: users(:ryan_doe).locale)
      end

      test 'User with role >= Analyst sees create export button' do
        user = users(:james_doe)
        sign_in user
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_menu_item('linelist_export', present: true, locale: user.locale)
        assert_actions_menu_item('sample_export', present: true, locale: user.locale)
      end

      test 'User with role < Analyst does not see create export button' do
        user = users(:ryan_doe)
        sign_in user
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_menu_item('linelist_export', present: false, locale: user.locale)
        assert_actions_menu_item('sample_export', present: false, locale: user.locale)
      end

      test 'User with role >= Maintainer sees import metadata button' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: @user.locale)
        assert_actions_menu_item('import_metadata', present: true, locale: @user.locale)
      end

      test 'User with role == Analyst sees sample actions dropdown but not import metadata button' do
        user = users(:michelle_doe)
        project = projects(:project24)
        sign_in user
        get namespace_project_samples_url(project.parent, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('import_metadata', present: false, locale: user.locale)
      end

      test 'User with role >= Maintainer sees new sample button' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: @user.locale)
        assert_actions_menu_item('new_sample', present: true, locale: @user.locale)
      end

      test 'User with role < Maintainer does not see new sample button' do
        user = users(:michelle_doe)
        project = projects(:project24)
        sign_in user
        get namespace_project_samples_url(project.parent, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('new_sample', present: false, locale: user.locale)
      end

      test 'User with role == Owner sees delete samples button' do
        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: @user.locale)
        assert_actions_menu_item('delete_samples', present: true, locale: @user.locale)
      end

      test 'User with role < Owner does not see delete samples button' do
        user = users(:michelle_doe)
        project = projects(:project24)
        sign_in user
        get namespace_project_samples_url(project.parent, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('delete_samples', present: false, locale: user.locale)
      end

      test 'cannot access project samples' do
        sign_in users(:user_no_access)
        get namespace_project_samples_url(@namespace, @project)

        assert_response :unauthorized
      end
    end
  end
end
