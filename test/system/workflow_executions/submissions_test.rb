# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @sample43 = samples(:sample43)
      @sample44 = samples(:sample44)
      @project = projects(:project37)
      @namespace = groups(:group_sixteen)
    end

    test 'should display a pipeline selection modal for project samples as owner' do
      user = users(:john_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should display a pipeline selection modal for project samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should display a pipeline selection modal for project samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_no_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should display a pipeline selection modal for project samples as analyst through namespace group link' do
      user = users(:user30)
      login_as user

      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)
      sample = samples(:sample45)

      visit namespace_project_samples_url(namespace_id: namespace.path, project_id: project.path)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 1, count: 1,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{sample.id}']").click
      end

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 1
          table.assert_selector '.table-column:first-child .table-td:first-child', text: sample.puid, count: 1
        end

        assert_no_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should not display a launch pipeline button for project samples as guest' do
      login_as users(:ryan_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_no_text I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'should display a pipeline selection modal for group samples as owner' do
      user = users(:john_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should display a pipeline selection modal for group samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should display a pipeline selection modal for group samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(Viral::Pagy::LimitComponent.translate('.summary', from: 1, to: 3, count: 3,
                                                                               locale: user.locale))

      within 'table' do
        find("input[type='checkbox'][value='#{@sample43.id}']").click
        find("input[type='checkbox'][value='#{@sample44.id}']").click
      end

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within 'dialog[open].dialog--size-xl' do
        assert_selector 'div.samplesheet-table' do |table|
          table.assert_selector '.table-column:first-child .table-td', count: 2
          table.assert_selector '.table-column:first-child .table-td:first-child', text: @sample43.puid, count: 1
          table.assert_selector '.table-column:first-child .table-td:nth-child(2)', text: @sample44.puid, count: 1
        end

        assert_no_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')
      end
    end

    test 'should not display a launch pipeline button for group samples as guest' do
      login_as users(:ryan_doe)

      visit group_samples_url(@namespace)

      assert_no_text I18n.t(:'groups.samples.index.workflows.button_sr')
    end

    test 'launch pipeline button is disabled when a project does not contain any samples' do
      login_as users(:empty_doe)

      visit namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                          project_id: projects(:empty_project).path)

      assert_no_button I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'launch pipeline button is disabled when a group does not contain any projects with samples' do
      login_as users(:empty_doe)

      visit group_samples_url(groups(:empty_group))

      assert_no_button I18n.t(:'projects.samples.index.workflows.button_sr')
    end
  end
end
