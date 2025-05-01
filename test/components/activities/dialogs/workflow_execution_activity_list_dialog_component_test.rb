# frozen_string_literal: true

require 'application_system_test_case'

module Activities
  module Dialogs
    class WorkflowExecutionActivityListDialogComponentTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
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
        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                                       user: @user.email, count: 1)

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: workflow_execution.name
          assert_selector 'li > p > span:nth-child(2)', text: workflow_execution.id
        end
      end
    end
  end
end
