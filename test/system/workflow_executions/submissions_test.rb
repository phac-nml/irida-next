# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'should display a pipeline selection modal for project samples' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      find("input[type='checkbox'][value='#{@sample1.id}']").click
      find("input[type='checkbox'][value='#{@sample2.id}']").click

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')
      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample1.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample2.puid, count: 1
          end
        end
      end
    end

    test 'should display a pipeline selection modal for group samples' do
      visit group_samples_url(@namespace)

      find("input[type='checkbox'][value='#{@sample1.id}']").click
      find("input[type='checkbox'][value='#{@sample2.id}']").click

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')
      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample1.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample2.puid, count: 1
          end
        end
      end
    end

    test 'should not display a launch pipeline button for group samples' do
      user = users(:ryan_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_no_text I18n.t(:'groups.samples.index.workflows.button_sr')
    end
  end
end
