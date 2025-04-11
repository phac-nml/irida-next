# frozen_string_literal: true

require 'view_component_test_case'

module Activities
  module Dialogs
    class WorkflowExecutionDestroyActivityDialogComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
      end

      test 'workflow execution destroy activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('activity.namespaces_project_namespace.workflow_executions.destroy_html')
        end)

        @activity_owner = I18n.t('activerecord.concerns.track_activity.system')

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.workflow_executions.destroy_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::WorkflowExecutionDestroyActivityDialogComponent.new(
          activity: activity_to_render,
          activity_owner: @activity_owner
        )

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                                     user: 'System', count: 3)

        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 4
        assert_selector 'tr > th',
                        text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.id')
        assert_selector 'tr > th',
                        text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.name')
        assert_selector 'tr > td', text: 'first_workflow_id'
        assert_selector 'tr > td', text: 'first_workflow_name'
        assert_selector 'tr > td', text: 'second_workflow_id'
        assert_selector 'tr > td', text: 'second_workflow_name'
        assert_selector 'tr > td', text: 'third_workflow_id'
        assert_selector 'tr > td', text: 'third_workflow_name'
      end
    end
  end
end
