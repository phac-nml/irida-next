# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)

      @samplesheet_properties_payload = {
        sample: {
          type: 'string',
          pattern: '^\\S+$',
          meta: ['id'],
          unique: true,
          errorMessage: 'Sample name must be provided and cannot contain spaces',
          required: true,
          cell_type: 'sample_cell'
        },
        fastq_1: { # rubocop:disable Naming/VariableNumber
          type: 'string',
          pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
          errorMessage: "FastQ file for reads 1 must be provided, cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'", # rubocop:disable Layout/LineLength
          required: true,
          cell_type: 'fastq_cell',
          autopopulate: true
        },
        fastq_2: { # rubocop:disable Naming/VariableNumber
          errorMessage: "FastQ file for reads 2 cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'", # rubocop:disable Layout/LineLength
          anyOf: [
            {
              type: 'string',
              pattern: '^\\S+\\.f(ast)?q(\\.gz)?$'
            },
            {
              type: 'string',
              maxLength: 0
            }
          ],
          required: false,
          cell_type: 'fastq_cell',
          pattern: '^\\S+\\.f(ast)?q(\\.gz)?$',
          autopopulate: true
        }
      }.to_json
    end

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

    test 'pipeline selection request with no disabled buttons' do
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 2, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify ordering
      assert_select 'li', 5 do |workflow_selection_text|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_text[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline',
                     workflow_selection_text[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_text[2].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_text[3].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_text[4].text.squish
      end

      # no disabled buttons or Unavailable divider
      assert_select 'button[aria-disabled="true"]', count: 0
      assert_select 'span', text: I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'), count: 0
    end

    test 'pipeline selection request with minimum samples error' do
      disabled_button_text = "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{I18n.t(
        'shared.workflow_executions.sample_limits.min_samples_required', min_samples: 2
      )}"
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 1, format: :turbo_stream)
      assert_response :success
      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify button text and ordering (includes Unavailable divider)
      assert_select 'li', 6 do |workflow_selection_text|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_text[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_text[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_text[2].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_text[3].text.squish
        assert_equal I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'),
                     workflow_selection_text[4].text.squish
        assert_equal disabled_button_text, workflow_selection_text[5].text.squish
      end
      assert_select 'button[aria-disabled="true"]', disabled_button_text
    end

    test 'pipeline selection request with maximum samples error' do
      disabled_button_text = "phac-nml/iridanextexample 1.0.3 IRIDA Next Example Pipeline #{I18n.t(
        'shared.workflow_executions.sample_limits.max_samples_exceeded', max_samples: 2
      )}"
      get pipeline_selection_workflow_executions_submissions_path(@group, sample_count: 100, format: :turbo_stream)
      assert_response :success
      assert_select 'h1', I18n.t('workflow_executions.submissions.pipeline_selection.title')

      # verify button text and ordering (includes Unavailable divider)
      assert_select 'li', 6 do |workflow_selection_text|
        assert_equal 'phac-nml/gasclustering 0.4.2 Genomic Address Service Clustering Workflow',
                     workflow_selection_text[0].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.2 IRIDA Next Example Pipeline',
                     workflow_selection_text[1].text.squish
        assert_equal 'phac-nml/iridanextexample 1.0.1 IRIDA Next Example Pipeline',
                     workflow_selection_text[2].text.squish
        assert_equal 'phac-nml/snvphylnfc 2.4.0 SNVPhyl nf-core pipeline', workflow_selection_text[3].text.squish
        assert_equal I18n.t('workflow_executions.submissions.pipeline_selection.unavailable'),
                     workflow_selection_text[4].text.squish
        assert_equal disabled_button_text, workflow_selection_text[5].text.squish
      end
      assert_select 'button[aria-disabled="true"]', disabled_button_text
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

    test 'can get nextflow samplesheet' do
      sign_in users(:john_doe)
      post workflow_executions_submissions_path(namespace_id: projects(:project1).namespace.id,
                                                pipeline_id: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.3',
                                                sample_count: 1, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', 'phac-nml/iridanextexample'

      assert_select 'label', "#{I18n.t('components.nextflow_component.name.label.required')} *"
      assert_select 'input[id="workflow_execution_name"][type="text"]'
      assert_select 'div', I18n.t('components.nextflow_component.loading_samplesheet.one')
      assert_select 'span', I18n.t(:'components.nextflow.verifying_update_samples')
      assert_select 'label', I18n.t(:'components.nextflow.email_notification')
      assert_select 'label', I18n.t(:"components.nextflow.shared_with.#{projects(:project1).namespace.type.downcase}")
    end

    test 'role analyst cannot update samples' do
      sign_in users(:michelle_doe)

      post samplesheet_workflow_executions_submissions_path(properties: @samplesheet_properties_payload,
                                                            sample_ids: [samples(:sample1).id],
                                                            format: :turbo_stream)

      assert_response :success

      assert_includes response.body, 'data-allowed-to-update-samples="false"'
    end

    test 'role analyst cannot update samples for a shared project' do
      sign_in users(:subgroup_sample_actions_doe)

      post samplesheet_workflow_executions_submissions_path(properties: @samplesheet_properties_payload,
                                                            sample_ids: [samples(:sample71).id],
                                                            format: :turbo_stream)

      assert_response :success

      assert_includes response.body, 'data-allowed-to-update-samples="false"'
    end

    test 'role maintainer can update samples' do
      sign_in users(:john_doe)

      post samplesheet_workflow_executions_submissions_path(properties: @samplesheet_properties_payload,
                                                            sample_ids: [samples(:sample1).id],
                                                            format: :turbo_stream)

      assert_response :success

      assert_includes response.body, 'data-allowed-to-update-samples="true"'
    end
  end
end
