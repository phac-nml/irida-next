# frozen_string_literal: true

require 'view_component_test_case'

class ProjectDashboardComponentTest < ViewComponentTestCase
  test 'display project dashboard on details page' do
    project = projects(:project1)
    project_activities = project.namespace.retrieve_project_activity.order(created_at: :desc).limit(10)
    activities = project.namespace.human_readable_activity(project_activities)
    samples = project.samples.order(updated_at: :desc).limit(10)

    render_inline ProjectDashboardComponent.new(activities:, samples:, project:)

    assert_text I18n.t('components.project_dashboard.activity_title'), count: 1
    assert_text I18n.t('components.project_dashboard.samples_title'), count: 1
    assert_text I18n.t('components.project_dashboard.info_title'), count: 1

    assert_selector 'li.activity', count: 10
    assert_selector 'li.sample', count: [project.samples.count, 10].min
  end
end
