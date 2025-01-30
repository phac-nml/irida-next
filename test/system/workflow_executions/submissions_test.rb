# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @sample22 = samples(:sample22)
      @sample43 = samples(:sample43)
      @sample44 = samples(:sample44)
      @sample46 = samples(:sample46)
      @project2 = projects(:project2)
      @project = projects(:project37)
      @group1 = groups(:group_one)
      @namespace = groups(:group_sixteen)

      @user = users(:jeff_doe)
      login_as @user
      @jeff_doe_namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      @project_a = projects(:projectA)
      @sample_a = samples(:sampleA)
      @sample_b = samples(:sampleB)
      @attachment_c = attachments(:attachmentC)
      @attachment_fwd2 = attachments(:attachmentPEFWD2)
      @attachment_rev2 = attachments(:attachmentPEREV2)
      @attachment_fwd3 = attachments(:attachmentPEFWD3)
      @attachment_rev3 = attachments(:attachmentPEREV3)
      @attachment_fwd43 = attachments(:attachmentPEFWD43)
      @attachment_rev43 = attachments(:attachmentPEREV43)

      Sample.reindex
      Searchkick.enable_callbacks
    end

    teardown do
      Searchkick.disable_callbacks
    end

    test 'should display a pipeline selection modal for project samples as owner' do
      user = users(:john_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
      end
    end

    test 'should display a pipeline selection modal for project samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
      end
    end

    test 'should display a pipeline selection modal for project samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
      end
    end

    test 'should display a pipeline selection modal for project samples as analyst through namespace group link' do
      user = users(:user30)
      login_as user

      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)
      sample = samples(:sample45)
      Project.reset_counters(project.id, :samples_count)

      visit namespace_project_samples_url(namespace_id: namespace.path, project_id: project.path)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
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

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}")
      end
    end

    test 'should display a pipeline selection modal for group samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}")
      end
    end

    test 'should display a pipeline selection modal for group samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
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
        assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}")
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

    test 'default attachment selections' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### VERIFY START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_a.id}_fastq_1']", text: @attachment_c.file.filename.to_s
        assert_selector "div[id='#{@sample_a.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd3.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']", text: @attachment_rev3.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'associated attachment autopopulated after selecting paired end attachment' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd3.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']", text: @attachment_rev3.file.filename.to_s
        find("div[id='#{@sample_b.id}_fastq_1']").click
      end

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # select new attachment
          find("#attachment_id_#{@attachment_fwd2.id}").click
        end
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within '#dialog' do
        # both attachment fwd and rev3 were replaced with fwd and rev2
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd2.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']", text: @attachment_rev2.file.filename.to_s
        assert_no_text @attachment_fwd3.file.filename.to_s
        assert_no_text @attachment_rev3.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'associated attachment autopopulates to no file when selection changes from PE to non-PE' do
      attachment_d = attachments(:attachmentD)
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd3.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']", text: @attachment_rev3.file.filename.to_s
        find("div[id='#{@sample_b.id}_fastq_1']").click
      end

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # select new attachment
          find("#attachment_id_#{attachment_d.id}").click
        end
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within '#dialog' do
        # fastq_1 field changed to single-end fastq file, fastq_2 autopopulates to no selected file
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: attachment_d.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_no_text @attachment_fwd3.file.filename.to_s
        assert_no_text @attachment_rev3.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'associated attachment does not autopopulate after selecting non-pe attachment' do
      ### SETUP START ###
      attachment_b = attachments(:attachmentB)
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_a.id}_fastq_1']", text: @attachment_c.file.filename.to_s
        assert_selector "div[id='#{@sample_a.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        # launch file selector
        find("div[id='#{@sample_a.id}_fastq_1']").click
      end

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # select new attachment
          find("#attachment_id_#{attachment_b.id}").click
        end
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within '#dialog' do
        # only fastq_1 field was changed, fastq_2 remains empty
        assert_selector "div[id='#{@sample_a.id}_fastq_1']", text: attachment_b.file.filename.to_s
        assert_selector "div[id='#{@sample_a.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_no_text @attachment_c.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'no file option not available for required attachment fields' do
      ### SETUP START ###
      attachment_b = attachments(:attachmentB)
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_a.id}_fastq_1']", text: @attachment_c.file.filename.to_s
        assert_selector "div[id='#{@sample_a.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        # launch file selector
        find("div[id='#{@sample_a.id}_fastq_1']").click
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # verify other attachments loaded
          assert_selector "#attachment_id_#{attachment_b.id}"
          # verify no file option does not exist in required field
          assert_no_selector '#attachment_id_no_attachment'
        end
      end
      ### VERIFY END ###
    end

    test 'no file option for non-required attachment fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd3.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']", text: @attachment_rev3.file.filename.to_s
        find("div[id='#{@sample_b.id}_fastq_2']").click
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # verify no file option exists in non-required field
          assert_selector '#attachment_id_no_attachment'
          find('#attachment_id_no_attachment').click
        end
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      within('#dialog') do
        # sample_b fastq2 selection is now no file selected
        assert_selector "div[id='#{@sample_b.id}_fastq_1']", text: @attachment_fwd3.file.filename.to_s
        assert_selector "div[id='#{@sample_b.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_no_text @attachment_rev3.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'empty state of file selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: @user.locale))
      # select samples
      within 'table' do
        find("input[type='checkbox'][value='#{@sample_a.id}']").click
        find("input[type='checkbox'][value='#{@sample_b.id}']").click
      end
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample_a.id}_fastq_1']", text: @attachment_c.file.filename.to_s
        assert_selector "div[id='#{@sample_a.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        find("div[id='#{@sample_a.id}_fastq_2']").click
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # verify empty state
        assert_no_selector '#file_selector_form'
        assert_text I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.title')
        assert_text I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.description')
      end
      ### VERIFY END ###
    end

    test 'required attachments samplesheet validation' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      fwd_attachment = attachments(:attachmentPEFWD43)
      rev_attachment = attachments(:attachmentPEREV43)
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        # verify auto selected attachments
        assert_selector "div[id='#{@sample43.id}_fastq_1']",
                        text: fwd_attachment.file.filename.to_s
        assert_selector "div[id='#{@sample43.id}_fastq_2']", text: rev_attachment.file.filename.to_s

        assert_selector "div[id='#{@sample44.id}_fastq_1']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_selector "div[id='#{@sample44.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')

        assert_selector "div[id='#{@sample46.id}_fastq_1']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_selector "div[id='#{@sample46.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        # verify error msg has not rendered
        assert_no_text I18n.t('nextflow.samplesheet_component.data_missing_error')
        click_button I18n.t('workflow_executions.submissions.create.submit')
        ### ACTIONS END ###

        ### VERIFY START ###
        # verify error msg rendered
        assert_selector 'div[data-nextflow--samplesheet-target="error"]'
        within('div[data-nextflow--samplesheet-target="error"]') do
          assert_text I18n.t('nextflow_component.data_missing_error')
          assert_text "- #{@sample44.puid}: fastq_1"
          assert_text "- #{@sample46.puid}: fastq_1"
        end
        ### VERIFY END ###
      end
    end

    test 'samplesheet pagination' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: user.locale))
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      within '#dialog' do
        # verify pagination buttons as well as disabled previous state
        assert_selector 'button[data-action="click->nextflow--samplesheet#previousPage"][disabled]',
                        text: I18n.t('nextflow.samplesheet_component.previous')
        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '1'
        within('select[data-action="change->nextflow--samplesheet#pageSelected"]') do
          # verify only 4 pages exist
          assert_selector 'option[value="1"]'
          assert_selector 'option[value="2"]'
          assert_selector 'option[value="3"]'
          assert_selector 'option[value="4"]'
          assert_no_selector 'option[value="5"]'
        end
        assert_selector 'button[data-action="click->nextflow--samplesheet#nextPage"]',
                        text: I18n.t('nextflow.samplesheet_component.next')

        # navigate to page 2 of 4
        click_button I18n.t('nextflow.samplesheet_component.next')

        # verify previous button no longer disabled
        assert_selector 'button[data-action="click->nextflow--samplesheet#previousPage"]',
                        text: I18n.t('nextflow.samplesheet_component.previous')
        assert_no_selector 'button[data-action="click->nextflow--samplesheet#previousPage"][disabled]',
                           text: I18n.t('nextflow.samplesheet_component.previous')
        # page dropdown selection updated
        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '2'
        # navigate to page 3 of 4
        click_button I18n.t('nextflow.samplesheet_component.next')

        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '3'

        # test navigating by page dropdown selection
        find('select[data-action="change->nextflow--samplesheet#pageSelected"]').find('option[value="4"]').select_option

        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '4'
        # verify next button is disabled on last page
        assert_selector 'button[data-action="click->nextflow--samplesheet#nextPage"][disabled]',
                        text: I18n.t('nextflow.samplesheet_component.next')
      end
      ### ACTIONS AND VERIFY END ###
    end

    test 'data retained in samplesheet after data and page change' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      rev_attachment = attachments(:sample22AttachmentFastqREV)
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end

      within '#dialog' do
        # navigate to page 4
        find('select[data-action="change->nextflow--samplesheet#pageSelected"]').find('option[value="4"]').select_option
        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '4'

        # verify attachment to test initially has a selection
        assert_selector "div[id='#{@sample22.id}_fastq_2']",
                        text: rev_attachment.file.filename.to_s
        find("div[id='#{@sample22.id}_fastq_2']").click
      end

      # select 'No file' option
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        within('#file_selector_form') do
          # verify no file option exists in non-required field
          assert_selector '#attachment_id_no_attachment'
          find('#attachment_id_no_attachment').click
        end
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # file selection is now no file selected
        assert_selector "div[id='#{@sample22.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        # previously selected file no longer exists in table
        assert_no_text rev_attachment.file.filename.to_s
        # change page
        click_button I18n.t('nextflow.samplesheet_component.previous')
        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '3'
        assert_no_selector "div[id='#{@sample22.id}_fastq_2']"

        # navigate back to original page
        click_button I18n.t('nextflow.samplesheet_component.next')
        assert_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '4'
        # verify attachment selection is still 'No file' and original attachment does not exist in table
        assert_selector "div[id='#{@sample22.id}_fastq_2']",
                        text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
        assert_no_text rev_attachment.file.filename.to_s
      end
      ### VERIFY END ###
    end

    test 'pagination does not render if only one page of samples' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                           locale: user.locale))
      # select samples
      click_button I18n.t(:'projects.samples.index.select_all_button')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      within %(turbo-frame[id="samples_dialog"]) do
        assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
        assert_button text: 'phac-nml/iridanextexample', count: 3
        first('button', text: 'phac-nml/iridanextexample').click
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within '#dialog' do
        # verify samples samplesheet loaded
        assert_selector 'div.sample-sheet'
        within('#metadata-sample-column') do
          assert_text @sample43.puid
          assert_text @sample44.puid
          assert_text @sample46.puid
        end
        ### ACTIONS END ###

        ### VERIFY START ###
        # verify no pagination buttons rendered
        assert_no_selector '#samplesheet_pagination'
        assert_no_selector 'button[data-action="click->nextflow--samplesheet#previousPage"][disabled]',
                           text: I18n.t('nextflow.samplesheet_component.previous')
        assert_no_selector 'select[data-action="change->nextflow--samplesheet#pageSelected"]', text: '1'

        assert_no_selector 'button[data-action="click->nextflow--samplesheet#nextPage"]',
                           text: I18n.t('nextflow.samplesheet_component.next')

        ### VERIFY END ###
      end
    end
  end
end
