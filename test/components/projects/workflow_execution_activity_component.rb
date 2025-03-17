# frozen_string_literal: true

require 'view_component_test_case'

module Projects
  class TransferActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'destroy workflow execution' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('namespaces_project_namespace.workflow_executions.destroy_html')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.workflow_executions.destroy_html'
      end

      render_inline Activities::Projects::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.workflow_executions.destroy_html',
          user: 'System',
          href: activity_to_render[:workflow_execution_id]
        )
      )

      assert_selector 'a[disabled="disabled"]', text: activity_to_render[:workflow_execution_id]
    end

    test 'destroy multiple workflow executions' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('namespaces_project_namespace.workflow_executions.destroy_multiple_html')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.workflow_executions.destroy_multiple_html'
      end

      render_inline Activities::Projects::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.workflow_executions.destroy_multiple_html',
          user: 'System',
          href: activity_to_render[:workflow_execution_ids]&.size
        )
      )

      assert_selector 'a[disabled="disabled"]', text: activity_to_render[:workflow_execution_ids]&.size
    end
  end
end
