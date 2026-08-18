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
  end
end
