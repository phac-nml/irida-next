# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionsTest < ActionDispatch::IntegrationTest
    test 'launch pipeline button in project samples page with role >= Analyst' do
      sign_in users(:michelle_doe)
      get namespace_project_samples_url(groups(:group_one), projects(:project1))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'no launch pipeline button in project samples page with Guest role' do
      sign_in users(:ryan_doe)
      get namespace_project_samples_url(groups(:group_one), projects(:project1))

      assert_select 'button', text: I18n.t(:'projects.samples.index.workflows.button_sr'), count: 0
    end

    test 'no launch pipeline button in project with no samples' do
      sign_in users(:empty_doe)

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

    test 'pipeline selection request' do
      sign_in users(:john_doe)

      get pipeline_selection_workflow_executions_submissions_path(format: :turbo_stream)
      assert_response :success

      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify ordering
      assert_select 'ul > li > button', 5 do |workflow_selection_button|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_button[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline',
                     workflow_selection_button[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_button[2].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_button[3].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_button[4].text.squish
      end
    end

    test 'samplesheet request' do
      sign_in users(:john_doe)
      sample1 = samples(:sample1)
      post workflow_executions_submissions_path(namespace_id: projects(:project1).namespace.id,
                                                pipeline_id: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.3',
                                                samples: [sample1.id], format: :turbo_stream)

      assert_response :success
      assert_select 'h1', 'phac-nml/iridanextexample'
    end

    # TODO: Look into recreating this
    # test '@fields in create' do
    #   post workflow_executions_submissions_path(format: :turbo_stream,
    #                                             pipeline_id: 'phac-nml/iridanextexample',
    #                                             workflow_version: '1.0.2', namespace_id: @group.id)
    #   assert_response :ok
    #   assert_equal ['metadata field with spaces', 'metadatafield1', 'metadatafield2', 'unique.metadata.field'],
    #                @controller.instance_eval('@fields', __FILE__, __LINE__)
    # end
  end
end
