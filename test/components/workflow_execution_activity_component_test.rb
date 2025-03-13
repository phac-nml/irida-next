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

  test 'automated workflow execution setup activity' do
    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.create')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.create_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.create_html', user: 'System',
                                                                           href: @automated_workflow_execution.id)
    )
    assert_selector 'a',
                    text: @automated_workflow_execution.id
  end

  test 'automated workflow execution destroy activity' do
    ::AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow_execution, @user).execute

    activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.destroy')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.workflow_execution.automated_workflow.destroy_html'
    end

    render_inline Activities::WorkflowExecutionActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.workflow_execution.automated_workflow.destroy_html', user: @user.email,
                                                                            href: @automated_workflow_execution.id)
    )
    assert_selector 'span',
                    text: @automated_workflow_execution.id
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
    params = { sample: @sample1 }
    ::Samples::DestroyService.new(@project, @user, params).execute
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
    ::WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute
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
    ::WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute
    ::WorkflowExecutions::DestroyService.new(@user, { workflow_execution: @workflow_execution }).execute
    params = { sample: @sample1 }
    ::Samples::DestroyService.new(@project, @user, params).execute

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
