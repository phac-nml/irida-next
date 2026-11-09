# frozen_string_literal: true

require 'view_component_test_case'

class WorkflowExecutionActivityComponentTest < ViewComponentTestCase
  include ActionView::Helpers::SanitizeHelper

  setup do
    @user = users(:john_doe)
    @project = projects(:project1)
    @automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    @workflow_execution = workflow_executions(:workflow_execution_valid)
    @sample1 = samples(:sample1)
  end

  test 'workflow launched on sample activity' do
    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.launch')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.launch_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.launch_html', user: @user.email,
                                                                           href: @workflow_execution.id,
                                                                           sample_href: @sample1.puid)
    )

    assert_selector 'a', text: @workflow_execution.id
    assert_selector 'a', text: @sample1.puid
  end

  test 'workflow launched on sample and sample deleted activity' do
    Projects::Samples::DestroyService.new(@project.namespace, @user, { sample_ids: [@sample1.id] }).execute
    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.launch')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.launch_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.launch_html', user: @user.email,
                                                                           href: @workflow_execution.id,
                                                                           sample_href: @sample1.puid)
    )

    assert_selector 'a', text: @workflow_execution.id
    assert_selector 'span', text: @sample1.puid
  end

  test 'workflow launched on sample and workflow execution deleted activity' do
    ::WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute
    ::WorkflowExecutions::DestroyService.new(@user, { workflow_execution: @workflow_execution }).execute
    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.launch')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.launch_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.launch_html', user: @user.email,
                                                                           href: @workflow_execution.id,
                                                                           sample_href: @sample1.puid)
    )

    assert_selector 'span', text: @workflow_execution.id
    assert_selector 'a', text: @sample1.puid
  end

  test 'workflow launched on sample and both sample and workflow execution deleted activity' do
    ::WorkflowExecutions::CancelService.new(@user, { workflow_execution: @workflow_execution }).execute
    ::WorkflowExecutions::DestroyService.new(@user, { workflow_execution: @workflow_execution }).execute

    Projects::Samples::DestroyService.new(@project.namespace, @user, { sample_ids: [@sample1.id] }).execute

    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.launch')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.launch_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.launch_html', user: @user.email,
                                                                           href: @workflow_execution.id,
                                                                           sample_href: @sample1.puid)
    )

    assert_selector 'span', text: @workflow_execution.id
    assert_selector 'span', text: @sample1.puid
  end
end
