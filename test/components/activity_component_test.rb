# frozen_string_literal: true

require 'view_component_test_case'

class ActivityComponentTest < ViewComponentTestCase
  test 'listing of project activity' do
    project_namespace = projects(:project1).namespace
    project2_namespace = projects(:project2).namespace

    @activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
    @project2_activities = project2_namespace.human_readable_activity(
      project2_namespace.retrieve_project_activity
    ).reverse

    # Limit set to 10 per page
    @pagy = Pagy.new(count: 13, page: 1, limit: 10)

    assert_equal 13, @activities.length
    assert_equal 3, @project2_activities.length

    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.samples.create') })
    assert_equal(2, @activities.count { |activity| activity[:key].include?('project_namespace.member.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.samples.clone') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('project_namespace.samples.transfer') })
    assert_equal(1, @activities.count do |activity|
      activity[:key].include?('workflow_execution.automated_workflow.create')
    end)
    assert_equal(1, @activities.count do |activity|
                      activity[:key].include?('workflow_execution.automated_workflow.launch')
                    end)
    assert_equal(1, @activities.count { |activity| activity[:key].include?('namespace_group_link.create') })

    assert_equal(1, @activities.count do |activity|
      activity[:key].include?('namespaces_project_namespace.transfer')
    end)

    assert_equal(1, @project2_activities.count { |activity| activity[:key].include?('project_namespace.create') })
    assert_equal(1, @project2_activities.count do |activity|
                      activity[:key].include?('project_namespace.samples.cloned_from')
                    end)

    render_inline ActivityComponent.new(activities: @activities, pagy: @pagy)

    assert_selector 'li', count: @activities.length
    assert_selector 'time', count: @activities.length
    assert_selector 'p', count: @activities.length
    assert_button text: 'Load more', count: 1

    # Limit set to 10 per page
    @pagy = Pagy.new(count: 2, page: 1, limit: 10)

    render_inline ActivityComponent.new(activities: @project2_activities, pagy: @pagy)

    assert_selector 'li', count: @project2_activities.length
    assert_selector 'time', count: @project2_activities.length
    assert_selector 'p', count: @project2_activities.length
    assert_button text: 'Load more', count: 0
  end

  test 'listing of group activity' do
    group = groups(:group_one)

    @activities = group.human_readable_activity(group.retrieve_group_activity).reverse

    # Limit set to 10 per page
    @pagy = Pagy.new(count: 9, page: 1, limit: 10)

    assert_equal 9, @activities.length

    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.subgroups.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.projects.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.projects.transfer_out') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.projects.transfer_in') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.member.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.namespace_group_link.create') })
    assert_equal(1, @activities.count { |activity| activity[:key].include?('group.import_samples.create') })

    render_inline ActivityComponent.new(activities: @activities, pagy: @pagy)

    assert_selector 'li', count: @activities.length
    assert_selector 'time', count: @activities.length
    assert_selector 'p', count: @activities.length
    assert_button text: 'Load more', count: 0
  end
end
