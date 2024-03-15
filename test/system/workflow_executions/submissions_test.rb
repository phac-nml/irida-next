# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @sample38 = samples(:sample38)
      @sample39 = samples(:sample39)
      @project = projects(:project35)
      @namespace = groups(:group_fifteen)
    end

    test 'should display a pipeline selection modal for project samples' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_css 'button', text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should display a pipeline selection modal for group samples as owner' do
      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_css 'button', text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should display a pipeline selection modal for group samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_css 'button', text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should display a pipeline selection modal for group samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within 'dialog[open]' do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_css 'button', text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        within 'div.sample-sheet' do
          within 'table' do
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should not display a launch pipeline button for group samples as guest' do
      user = users(:ryan_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_no_text I18n.t(:'groups.samples.index.workflows.button_sr')
    end
  end
end
