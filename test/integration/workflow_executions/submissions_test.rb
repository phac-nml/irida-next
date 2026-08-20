# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionsTest < ActionDispatch::IntegrationTest
    test 'launch pipeline button in project samples page with role >= Analyst' do
      login_as users(:james_doe)
      get namespace_project_samples_url(groups(:group_one), projects(:project1))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'no launch pipeline button in project samples page with Guest role' do
      login_as users(:ryan_doe)
      get namespace_project_samples_url(groups(:group_one), projects(:project1))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end

    test 'no launch pipeline button in project with no samples' do
      login_as users(:empty_doe)

      get namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                        project_id: projects(:empty_project).path)

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end

    test 'launch pipeline button in group samples page with role >= Analyst' do
      group = groups(:group_sixteen)
      sign_in users(:james_doe)

      get group_samples_url(group)

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end

    test 'no launch pipeline button in group samples page with Guest' do
      sign_in users(:ryan_doe)

      get group_samples_url(groups(:group_one))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end

    test 'no launch pipeline button in group with no samples' do
      login_as users(:empty_doe)

      get group_samples_url(groups(:empty_group))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end
  end
end
