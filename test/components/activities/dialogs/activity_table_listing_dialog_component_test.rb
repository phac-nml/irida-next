# frozen_string_literal: true

require 'application_system_test_case'

module Activities
  module Dialogs
    class ActivityTableListingDialogComponentTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
      end

      test 'sample clone activity dialog source project' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.clone')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.clone_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        load_more_button = find('button', text: 'Load more')
        click_button 'Load more' if load_more_button

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_clone').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_clone.target_project_description',
                                       user: 'System', count: 1,
                                       target_project_puid: 'INXT_PRJ_AAAAAAAAAB')

          assert_selector 'table', count: 1
          assert_selector 'th', count: 2
          assert_selector 'tr', count: 2
          assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from').upcase
          assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to').upcase
          assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
          assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
        end
      end

      test 'sample clone activity dialog target project' do
        project_namespace = namespaces_project_namespaces(:project2_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.cloned_from')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.cloned_from_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_clone').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_clone.source_project_description',
                                     user: 'System', count: 1,
                                     source_project_puid: 'INXT_PRJ_AAAAAAAAAA')
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to').upcase
        assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
      end

      test 'workflow execution destroy activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)
        workflow_execution = workflow_executions(:automated_example_canceled)
        ::WorkflowExecutions::DestroyService.new(@user,
                                                 { workflow_execution:,
                                                   namespace: project_namespace }).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(2, activities.count do |activity|
          activity[:key].include?('activity.namespaces_project_namespace.workflow_executions.destroy_html')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.workflow_executions.destroy_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'workflow_executions_destroy').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                                     user: @user.email, count: 1)
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.name').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.id').upcase
        assert_selector 'tr > td', text: workflow_execution.name
        assert_selector 'tr > td', text: workflow_execution.id
      end
    end
  end
end
