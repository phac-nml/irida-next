# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
    end

    test 'pipeline selection request with no disabled buttons' do
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 2, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify ordering
      assert_select 'button[data-workflow-selection-target="workflow"]', 5 do |workflow_selection_button|
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

      assert_select 'button[aria-disabled="true"]', count: 0
      assert_select 'span', text: I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'), count: 0
    end

    test 'pipeline selection request with minimum samples error' do
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 1, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify ordering
      assert_select 'button[data-workflow-selection-target="workflow"]', 5 do |workflow_selection_button|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_button[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_button[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_button[2].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_button[3].text.squish
        assert_equal "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{I18n.t(
          'shared.workflow_executions.sample_limits.min_samples_required', min_samples: 2
        )}", workflow_selection_button[4].text.squish
      end
      assert_select 'button[aria-disabled="true"]', "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{
        I18n.t(
          'shared.workflow_executions.sample_limits.min_samples_required', min_samples: 2
        )}"
      assert_select 'span', text: I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'), count: 1
    end

    test 'pipeline selection request with maximum samples error' do
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 100, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify ordering
      assert_select 'button[data-workflow-selection-target="workflow"]', 5 do |workflow_selection_button|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_button[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_button[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_button[2].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_button[3].text.squish
        assert_equal "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{I18n.t(
          'shared.workflow_executions.sample_limits.max_samples_exceeded', max_samples: 2
        )}", workflow_selection_button[4].text.squish
      end
      assert_select 'button[aria-disabled="true"]', "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{
        I18n.t(
          'shared.workflow_executions.sample_limits.max_samples_exceeded', max_samples: 2
        )}"
      assert_select 'span', text: I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'), count: 1
    end
  end
end
