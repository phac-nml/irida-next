# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionsTest < ActionDispatch::IntegrationTest
    test 'can view pipeline launch dialog with role >= Analyst at group level' do
      group = groups(:group_sixteen)
      sign_in users(:james_doe)
      get pipeline_selection_workflow_executions_submissions_path(group, params: { namespace_id: group.id })
      assert_response :success

      assert_select 'ul' do
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline'
        end
      end
    end

    test 'cannot view pipeline launch dialog with Guest role at group level' do
      group = groups(:group_sixteen)
      sign_in users(:ryan_doe)
      get pipeline_selection_workflow_executions_submissions_path(group, params: { namespace_id: group.id })
      assert_response :unauthorized
    end

    test 'can view pipeline launch dialog with role >= Analyst at project level' do
      project = projects(:project37)
      namespace = project.namespace
      sign_in users(:james_doe)
      get pipeline_selection_workflow_executions_submissions_path(namespace, project,
                                                                  params: { namespace_id: namespace.id })
      assert_response :success

      assert_select 'ul' do
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline'
        end
      end
    end

    test 'cannot view pipeline launch dialog with Guest role at project level' do
      project = projects(:project37)
      namespace = project.namespace
      sign_in users(:ryan_doe)
      get pipeline_selection_workflow_executions_submissions_path(namespace, project,
                                                                  params: { namespace_id: namespace.id })
      assert_response :unauthorized
    end

    test 'can view pipeline launch dialog through group link' do
      project = projects(:user29_project1)
      sign_in users(:user30)
      get pipeline_selection_workflow_executions_submissions_path(project,
                                                                  params: { namespace_id: project.namespace.id })
      assert_response :success

      assert_select 'ul' do
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline'
        end
        assert_select 'li' do
          assert_select 'button', text: 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline'
        end
      end
    end

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
