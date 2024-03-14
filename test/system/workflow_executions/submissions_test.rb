# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    setup do
      @sample38 = samples(:sample38)
      @sample39 = samples(:sample39)
      @project = projects(:project35)
      @namespace = groups(:group_fifteen)
    end

    test 'should display a pipeline selection modal for project samples as owner' do
      login_as users(:john_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')

        # The below line is currently commented out as it is finding 6 instances when there are only 3
        # on the page. We need to dig further into why this is happening on the CI and not locally.

        assert_button text: 'phac-nml/iridanextexample', count: 3
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

    test 'should display a pipeline selection modal for project samples as maintainer' do
      login_as users(:joan_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

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
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should display a pipeline selection modal for project samples as analyst' do
      login_as users(:james_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

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
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample38.puid, count: 1
            assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample39.puid, count: 1
          end
        end
      end
    end

    test 'should not display a launch pipeline button for project samples as guest' do
      login_as users(:ryan_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_no_text I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'should display a pipeline selection modal for group samples as owner' do
      login_as users(:john_doe)

      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')

        # The below line is currently commented out as it is finding 6 instances when there are only 3
        # on the page. We need to dig further into why this is happening on the CI and not locally.

        assert_button text: 'phac-nml/iridanextexample', count: 3
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
      login_as users(:joan_doe)

      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')

        # The below line is currently commented out as it is finding 6 instances when there are only 3
        # on the page. We need to dig further into why this is happening on the CI and not locally.

        assert_button text: 'phac-nml/iridanextexample', count: 3
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
      login_as users(:james_doe)

      visit group_samples_url(@namespace)

      within 'table' do
        find("input[type='checkbox'][value='#{@sample38.id}']").click
        find("input[type='checkbox'][value='#{@sample39.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')

        # The below line is currently commented out as it is finding 6 instances when there are only 3
        # on the page. We need to dig further into why this is happening on the CI and not locally.

        assert_button text: 'phac-nml/iridanextexample', count: 3
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
      login_as users(:ryan_doe)

      visit group_samples_url(@namespace)

      assert_no_text I18n.t(:'groups.samples.index.workflows.button_sr')
    end
  end
end
