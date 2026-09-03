# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesTest < ActionDispatch::IntegrationTest
    include ActionView::RecordIdentifier

    setup do
      @user = users(:john_doe)
      sign_in @user
      @sample1 = samples(:sample1)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'index renders the samples table with headers and rows' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'h1', text: I18n.t('projects.samples.index.title')
      assert_samples_table_headers
      assert_select 'table tbody tr', count: 3
      assert_select "table tbody tr##{dom_id(@sample1)} th:first-child", text: /#{Regexp.escape(@sample1.puid)}/
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
    end

    test 'index renders the data grid when the flag is enabled' do
      Flipper.enable(:data_grid_samples_table)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_samples_data_grid
    ensure
      Flipper.disable(:data_grid_samples_table)
    end

    test 'user with role >= Analyst sees select and deselect controls' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select '#samples-table[data-controller~=?]', 'selection'
      assert_select 'button#select-all-button'
      assert_select 'button#deselect-all-button'
      assert_select 'form#select-all-form'
      assert_select 'form#deselect-all-form'
      assert_select 'input#select-page[data-selection-target=?]', 'selectPage'
      assert_select "input##{dom_id(@sample1, :checkbox)}[data-selection-target=?]", 'rowSelection'
    end

    test 'user with role < Analyst does not see select and deselect controls' do
      sign_in users(:ryan_doe)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button#select-all-button', count: 0
      assert_select 'button#deselect-all-button', count: 0
      assert_select 'input#select-page', count: 0
      assert_select "input##{dom_id(@sample1, :checkbox)}", count: 0
    end

    test 'user with role >= Analyst sees the workflow execution link' do
      user = users(:james_doe)
      sign_in user

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'span',
                    text: /#{Regexp.escape(I18n.t('projects.samples.index.workflows.button_sr', locale: user.locale))}/
    end

    test 'user with role < Analyst does not see the workflow execution link' do
      sign_in users(:ryan_doe)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'span',
                    text: /#{Regexp.escape(I18n.t('projects.samples.index.workflows.button_sr'))}/, count: 0
    end

    test 'user with role >= Analyst sees the sample actions dropdown' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'user with role < Analyst does not see the sample actions dropdown' do
      sign_in users(:ryan_doe)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label'), count: 0
    end

    test 'user with role >= Analyst sees the export actions' do
      user = users(:james_doe)
      sign_in user

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]',
                    text: /#{Regexp.escape(I18n.t('shared.samples.actions_dropdown.linelist_export',
                                                  locale: user.locale))}/
      assert_select 'button[role="menuitem"]',
                    text: /#{Regexp.escape(I18n.t('shared.samples.actions_dropdown.sample_export',
                                                  locale: user.locale))}/
    end

    test 'user with role < Analyst does not see the export actions' do
      sign_in users(:ryan_doe)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.linelist_export'),
                                               count: 0
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.sample_export'), count: 0
    end

    test 'user with role >= Maintainer sees the import metadata action' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.import_metadata')
    end

    test 'user with role == Analyst does not see the import metadata action' do
      project = projects(:project24)
      sign_in users(:michelle_doe)

      get namespace_project_samples_url(project.parent, project)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label')
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.import_metadata'), count: 0
    end

    test 'user with role >= Maintainer sees the new sample action' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.new_sample')
    end

    test 'user with role < Maintainer does not see the new sample action' do
      project = projects(:project24)
      sign_in users(:michelle_doe)

      get namespace_project_samples_url(project.parent, project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.new_sample'), count: 0
    end

    test 'user with role == Owner sees the delete samples action' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
    end

    test 'user with role < Owner does not see the delete samples action' do
      project = projects(:project24)
      sign_in users(:michelle_doe)

      get namespace_project_samples_url(project.parent, project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.delete_samples'), count: 0
    end

    test 'cannot access project samples without authorization' do
      sign_in users(:user_no_access)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :unauthorized
    end

    test 'quick search highlights matching sample names' do
      get namespace_project_samples_url(@namespace, @project, q: { name_or_puid_cont: 'sample' })

      assert_response :success
      assert_select 'table tbody tr', count: 3
      assert_select 'mark', minimum: 3
    end

    test 'quick search highlights matching sample puid' do
      get namespace_project_samples_url(@namespace, @project, q: { name_or_puid_cont: @sample1.puid })

      assert_response :success
      assert_select 'table tbody tr', count: 1
      assert_select 'mark', text: /#{Regexp.escape(@sample1.puid)}/
    end

    test 'renders the empty state when a project has no samples' do
      sign_in users(:empty_doe)

      get namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                        project_id: projects(:empty_project).path)

      assert_response :success
      assert_match I18n.t('projects.samples.index.no_samples'), response.body
      assert_match I18n.t('projects.samples.index.no_associated_samples'), response.body
    end
  end
end
