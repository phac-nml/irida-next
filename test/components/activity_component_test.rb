# frozen_string_literal: true

require 'view_component_test_case'

class ActivityComponentTest < ViewComponentTestCase
  test 'listing of project activity' do
    project_namespace = projects(:project1).namespace
    project2_namespace = projects(:project2).namespace

    @activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
    @project2_activities = project2_namespace.human_readable_activity(project2_namespace.retrieve_project_activity).reverse

    assert_equal 11, @activities.length
    assert_equal 2, @project2_activities.length

    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.sample.create') })
    assert_equal(2, @activities.count { |activity| activity[:key].include?('member.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.samples.clone') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.samples.transfer') })
    assert_equal(1, @activities.count do |activity|
                      activity[:key].include?('workflow_execution.automated_workflow.launch')
                    end)
    assert_equal(1, @activities.count { |activity| activity[:key].include?('namespace_group_link.create') })
    assert_equal(1, @activities.count do |activity|
                      activity[:key].include?('namespaces_project_namespace.samples.destroy_multiple')
                    end)
    assert_equal(1, @activities.count do |activity|
      activity[:key].include?('namespaces_project_namespace.transfer')
    end)
    assert_equal(1, @activities.count do |activity|
      activity[:key].include?('namespaces_project_namespace.samples.metadata.update')
    end)

    assert_equal(1, @project2_activities.count { |activity| activity[:key].include?('project_namespace.create') })
    assert_equal(1, @project2_activities.count do |activity|
                      activity[:key].include?('project_namespace.samples.cloned_from')
                    end)

    render_inline ActivityComponent.new(activities: @activities)

    assert_selector 'li', count: @activities.length
    assert_selector 'time', count: @activities.length
    assert_selector 'p', count: @activities.length

    render_inline ActivityComponent.new(activities: @project2_activities)

    assert_selector 'li', count: @project2_activities.length
    assert_selector 'time', count: @project2_activities.length
    assert_selector 'p', count: @project2_activities.length
  end
end
