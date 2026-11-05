# frozen_string_literal: true

require 'view_component_test_case'

class AutomatedPipelineActivityComponentTest < ViewComponentTestCase
  include ActionView::Helpers::SanitizeHelper

  setup do
    @user = users(:john_doe)
    @project = projects(:project1)
    @automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    @workflow_execution = workflow_executions(:workflow_execution_valid)
    @sample1 = samples(:sample1)
  end

  test 'automated workflow execution setup activity' do
    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('namespaces_project_namespace.automated_pipeline.create')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.automated_pipeline.create_html'
    end

    render_inline Activities::Projects::AutomatedPipelineActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.automated_pipeline.create_html',
             user: 'System',
             href: @automated_workflow_execution.id)
    )
    assert_selector 'a',
                    text: @automated_workflow_execution.id
  end

  test 'automated workflow execution destroy activity' do
    ::AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow_execution, @user).execute

    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('activity.namespaces_project_namespace.automated_pipeline.destroy')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.automated_pipeline.destroy_html'
    end

    render_inline Activities::Projects::AutomatedPipelineActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.automated_pipeline.destroy_html',
             user: @user.email,
             href: @automated_workflow_execution.id)
    )
    assert_selector 'a',
                    text: @automated_workflow_execution.id
  end
end
