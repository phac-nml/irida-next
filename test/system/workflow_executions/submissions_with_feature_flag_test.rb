# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  ### TODO: Rename this file to submissions_test.rb once feature flag deferred_samplesheet is retired
  class SubmissionsWithFeatureFlagTest < ApplicationSystemTestCase
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

      Flipper.enable(:deferred_samplesheet)
    end

    test 'should display a pipeline selection modal for project samples as owner' do
      user = users(:john_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples')
      assert_text I18n.t(:'components.nextflow.email_notification')
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
    end

    test 'should display a pipeline selection modal for project samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title',
                                                       locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}", locale: user.locale)
    end

    test 'should display a pipeline selection modal for project samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title',
                                                       locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.unauthorized_to_update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}", locale: user.locale)
    end

    test 'should display a pipeline selection modal for project samples as analyst through namespace group link' do
      user = users(:user30)
      login_as user

      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)
      sample = samples(:sample45)
      Project.reset_counters(project.id, :samples_count)
      visit namespace_project_samples_url(namespace_id: namespace.path, project_id: project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{sample.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 1
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: sample.puid

      assert_no_text I18n.t(:'components.nextflow.update_samples')
      assert_text I18n.t(:'components.nextflow.email_notification')
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
    end

    test 'cannot launch workflow execution (user launched) without a name' do
      user = users(:john_doe)
      login_as user

      project = projects(:project1)
      sample = samples(:sample1)
      Project.reset_counters(project.id, :samples_count)

      visit namespace_project_samples_url(project.namespace.parent, project)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      check "checkbox_sample_#{sample.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 1
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: sample.puid, count: 1

      assert_text I18n.t(:'components.nextflow.update_samples')
      assert_text I18n.t(:'components.nextflow.email_notification')
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")

      click_button I18n.t('workflow_executions.submissions.create.submit')

      assert_text I18n.t('components.nextflow_component.name.error')
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

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'groups.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples')
      assert_text I18n.t(:'components.nextflow.email_notification')
      assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}")
    end

    test 'should display a pipeline selection modal for group samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'groups.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title', locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}", locale: user.locale)
    end

    test 'should display a pipeline selection modal for group samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit group_samples_url(@namespace)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'groups.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title', locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.unauthorized_to_update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@namespace.type.downcase}", locale: user.locale)
    end

    test 'should not display a launch pipeline button for group samples as guest' do
      login_as users(:ryan_doe)

      visit group_samples_url(@namespace)

      assert_no_text I18n.t(:'groups.samples.index.workflows.button_sr')
    end

    test 'launch pipeline button is not displayed when a project does not contain any samples' do
      login_as users(:empty_doe)

      visit namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                          project_id: projects(:empty_project).path)

      assert_no_selector 'button',
                         text: I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'launch pipeline button is not displayed when a group does not contain any projects with samples' do
      login_as users(:empty_doe)

      visit group_samples_url(groups(:empty_group))

      assert_no_selector 'button',
                         text: I18n.t(:'projects.samples.index.workflows.button_sr')
    end

    test 'default attachment selections' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### VERIFY START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s
      ### VERIFY END ###
    end

    test 'associated attachment autopopulated after selecting paired end attachment' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s
      click_link "#{@sample_b.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{@attachment_fwd2.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
      # both attachment fwd and rev3 were replaced with fwd and rev2
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd2.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev2.file.filename.to_s
      assert_no_text @attachment_fwd3.file.filename.to_s
      assert_no_text @attachment_rev3.file.filename.to_s
      ### VERIFY END ###
    end

    test 'associated attachment autopopulates to no file when selection changes from PE to non-PE' do
      attachment_d = attachments(:attachmentD)
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s
      click_link "#{@sample_b.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_d.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')

      # fastq_1 field changed to single-end fastq file, fastq_2 autopopulates to no selected file
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: attachment_d.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text @attachment_fwd3.file.filename.to_s
      assert_no_text @attachment_rev3.file.filename.to_s
      ### VERIFY END ###
    end

    test 'associated attachment does not autopopulate after selecting non-pe attachment' do
      ### SETUP START ###
      attachment_b = attachments(:attachmentB)
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow executions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      # launch file selector
      click_link "#{@sample_a.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_b.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
      # only fastq_1 field was changed, fastq_2 remains empty
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: attachment_b.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text @attachment_c.file.filename.to_s
      ### VERIFY END ###
    end

    test 'no file option not available for required attachment fields' do
      ### SETUP START ###
      attachment_b = attachments(:attachmentB)
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      # launch file selector
      click_link "#{@sample_a.id}_fastq_1_file_link"
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
      # verify other attachments loaded
      assert_selector "#attachment_id_#{attachment_b.id}"
      # verify no file option does not exist in required field
      assert_no_selector '#attachment_id_no_attachment'
      ### VERIFY END ###
    end

    test 'no file option for non-required attachment fields' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"
      # click workflow exectuions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s
      click_link "#{@sample_b.id}_fastq_2_file_link"
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # verify no file option exists in non-required field
        assert_selector '#attachment_id_no_attachment'
        find('label[for="attachment_id_no_attachment"]').click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end

      # sample_b fastq2 selection is now no file selected
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text @attachment_rev3.file.filename.to_s
      ### VERIFY END ###
    end

    test 'empty state of file selection' do
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"
      # click workflow executions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      click_link "#{@sample_a.id}_fastq_2_file_link"
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify file selector rendered
      assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
      # verify empty state
      assert_no_selector '#file_selector_form'
      assert_text I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.title')
      assert_text I18n.t('workflow_executions.file_selector.file_selector_dialog.empty.description')
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
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###

      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      find('input#workflow_execution_name').fill_in with: 'TestExecution'
      # verify auto selected attachments
      assert_link "#{@sample43.id}_fastq_1_file_link",
                  text: fwd_attachment.file.filename.to_s
      assert_link "#{@sample43.id}_fastq_2_file_link", text: rev_attachment.file.filename.to_s

      assert_link "#{@sample44.id}_fastq_1_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_link "#{@sample44.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')

      assert_link "#{@sample46.id}_fastq_1_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_link "#{@sample46.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      # verify error msg has not rendered
      assert_no_text I18n.t('components.nextflow.samplesheet_component.data_missing_error')
      click_button I18n.t('workflow_executions.submissions.create.submit')
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify error msg rendered
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="error"]'
      assert_text I18n.t('components.nextflow_component.data_missing_error')
      assert_text "- #{@sample44.puid}: fastq_1"
      assert_text "- #{@sample46.puid}: fastq_1"
      ### VERIFY END ###
    end

    test 'samplesheet pagination' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'input[name="sample_ids[]"]:checked', count: 20

      assert_text 'Samples: 20'
      assert_selector 'strong[data-selection-target="selected"]', text: '20'

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      ### ACTIONS AND VERIFY START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify pagination buttons as well as disabled previous state
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        # verify only 4 pages exist
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
        assert_no_selector 'option[value="5"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')

      # navigate to page 2 of 4
      click_button I18n.t('components.nextflow.samplesheet_component.next')

      # verify previous button no longer disabled
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                         text: I18n.t('components.nextflow.samplesheet_component.previous')
      # page dropdown selection updated
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '2'
      # navigate to page 3 of 4
      click_button I18n.t('components.nextflow.samplesheet_component.next')

      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '3'

      # test navigating by page dropdown selection
      select '4', from: I18n.t('components.nextflow.samplesheet_component.page_selection.aria_label')

      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '4'
      # verify next button is disabled on last page
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      ### ACTIONS AND VERIFY END ###
    end

    test 'data retained in samplesheet after data and page change' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      rev_attachment = attachments(:sample22AttachmentFastqREV)
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'input[name="sample_ids[]"]:checked', count: 20

      assert_text 'Samples: 20'
      assert_selector 'strong[data-selection-target="selected"]', text: '20'

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_no_selector "a[id='#{@sample22.id}_fastq_2_file_link']"
      # navigate to page 4
      select '4', from: I18n.t('components.nextflow.samplesheet_component.page_selection.aria_label')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '4'

      # verify attachment to test initially has a selection
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: rev_attachment.file.filename.to_s
      click_link "#{@sample22.id}_fastq_2_file_link", text: rev_attachment.file.filename.to_s

      # select 'No file' option
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # verify no file option exists in non-required field
        assert_selector '#attachment_id_no_attachment'
        find('#attachment_id_no_attachment').click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # file selection is now no file selected
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      # previously selected file no longer exists in table
      assert_no_text rev_attachment.file.filename.to_s
      # change page
      click_button I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '3'
      assert_no_selector "a[id='#{@sample22.id}_fastq_2_file_link']"

      # navigate back to original page
      click_button I18n.t('components.nextflow.samplesheet_component.next')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '4'
      # verify attachment selection is still 'No file' and original attachment does not exist in table
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text rev_attachment.file.filename.to_s
      ### VERIFY END ###
    end

    test 'pagination does not render if only one page of samples' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'input[name="sample_ids[]"]:checked', count: 3

      assert_text 'Samples: 3'
      assert_selector 'strong[data-selection-target="selected"]', text: '3'
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')

      assert_selector "th[id='#{@sample43.id}_sample']", text: @sample43.puid
      assert_selector "th[id='#{@sample44.id}_sample']", text: @sample44.puid
      assert_selector "th[id='#{@sample46.id}_sample']", text: @sample46.puid
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify empty pagination container with no pagination buttons rendered
      # data-nextflow--deferred-samplesheet-target="paginationContainer"
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="paginationContainer"]'
      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                         text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_no_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'

      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                         text: I18n.t('components.nextflow.samplesheet_component.next')

      ### VERIFY END ###
    end

    test 'pagination filtering' do
      ### SETUP START ###
      user = users(:john_doe)
      sample3 = samples(:sample3)
      sample4 = samples(:sample4)
      sample5 = samples(:sample5)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify pagination buttons
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      # verify current samples listed
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_text sample3.puid
        assert_text sample4.puid
        assert_text sample5.puid
        assert_no_text @sample22.puid
        assert_selector 'tr', count: 5
      end
      # enter filter
      find('input#samplesheet-filter').fill_in with: @sample22.puid
      find('input#samplesheet-filter').send_keys :enter
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify above samples no longer listed and only the filter sample is rendered
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_no_text sample3.puid
        assert_no_text sample4.puid
        assert_no_text sample5.puid
        assert_text @sample22.puid
        assert_selector 'tr', count: 1
      end
      # verify pagination is removed because there is only 1 page of samples remaining
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="paginationContainer"]'
      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                         text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_no_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'

      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                         text: I18n.t('components.nextflow.samplesheet_component.next')
      ### VERIFY END ###
    end

    test 'samplesheet filtering still paginates' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify pagination buttons
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      # verify current samples listed
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 5
      end
      # enter filter
      find('input#samplesheet-filter').fill_in with: 'inxt_sam_'
      find('input#samplesheet-filter').send_keys(:return)
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector %(input#samplesheet-filter) do |input|
        assert_equal 'inxt_sam_', input['value']
      end
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody'
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 5
      end
      # verify 4 pages of samples still exist
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      ### VERIFY END ###
    end

    test 'samplesheet filtering empty state' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify pagination buttons
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      # verify current samples listed
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 5
      end
      # enter filter
      find('input#samplesheet-filter').fill_in with: 'not a valid filter'
      find('input#samplesheet-filter').send_keys :enter
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify no samples in samplesheet
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_no_selector 'tr'
      end

      # verify empty state
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="emptyState"]'
      assert_text I18n.t('components.viral.pagy.empty_state.title')
      assert_text I18n.t('components.viral.pagy.empty_state.description')

      # verify pagination is removed
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="paginationContainer"]'
      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                         text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_no_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'

      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                         text: I18n.t('components.nextflow.samplesheet_component.next')
      ### VERIFY END ###
    end

    test 'samplesheet filter search and clear buttons' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')
      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # verify pagination buttons
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      # verify current samples listed
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 5
      end

      # search button exists and clear button does not
      assert_selector 'button[data-nextflow--deferred-samplesheet-target="filterSearchButton"]'
      assert_no_selector 'button[data-nextflow--deferred-samplesheet-target="filterClearButton"]'
      # enter filter and click search button
      find('input#samplesheet-filter').fill_in with: 'INXT_SAM_AAAAAAAAAC'
      find('button[data-nextflow--deferred-samplesheet-target="filterSearchButton"]').click

      # verify only specified sample in samplesheet
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 1
        assert_text 'INXT_SAM_AAAAAAAAAC'
      end

      # verify pagination is removed
      assert_selector 'div[data-nextflow--deferred-samplesheet-target="paginationContainer"]'
      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                         text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_no_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'

      assert_no_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                         text: I18n.t('components.nextflow.samplesheet_component.next')

      # clear button exists and search button does not
      assert_no_selector 'button[data-nextflow--deferred-samplesheet-target="filterSearchButton"]'
      assert_selector 'button[data-nextflow--deferred-samplesheet-target="filterClearButton"]'

      # click clear button to remove filter
      find('button[data-nextflow--deferred-samplesheet-target="filterClearButton"]').click

      # verify pagination buttons
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#previousPage"][disabled]',
                      text: I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]', text: '1'
      within('select[data-action="change->nextflow--deferred-samplesheet#pageSelected"]') do
        assert_selector 'option[value="1"]'
        assert_selector 'option[value="2"]'
        assert_selector 'option[value="3"]'
        assert_selector 'option[value="4"]'
      end
      assert_selector 'button[data-action="click->nextflow--deferred-samplesheet#nextPage"]',
                      text: I18n.t('components.nextflow.samplesheet_component.next')
      # verify current samples listed
      within('table[data-test-selector="samplesheet-table"] tbody') do
        assert_selector 'tr', count: 5
      end

      # search button exists and clear button does not
      assert_selector 'button[data-nextflow--deferred-samplesheet-target="filterSearchButton"]'
      assert_no_selector 'button[data-nextflow--deferred-samplesheet-target="filterClearButton"]'
      ### ACTIONS AND VERIFY END ###
    end

    test 'samplesheet metadata selection changes samplesheet values' do
      ### SETUP START ###
      user = users(:john_doe)
      namespace = groups(:group_twelve)
      sample32 = samples(:sample32)
      sample33 = samples(:sample33)
      sample34 = samples(:sample34)
      sample35 = samples(:sample35)
      login_as user

      visit group_samples_url(namespace)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: user.locale))
      # select samples

      click_button I18n.t('common.controls.select_all')

      assert_selector 'input[name="sample_ids[]"]:checked', count: 4
      assert_selector 'strong[data-selection-target="selected"]', text: 4

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/gasclustering'
      click_button 'phac-nml/gasclustering'
      ### SETUP END ###

      ### ACTIONS START ###
      assert_selector 'h1', text: 'phac-nml/gasclustering'

      # check default metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadata_1'
      assert_selector '#field-metadata_2', text: 'metadata_2'

      assert_selector "td[id='#{sample32.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample33.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample34.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample35.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample32.id}_metadata_2'] input[type='text']", text: ''
      assert_selector "td[id='#{sample33.id}_metadata_2'] input[type='text']", text: ''
      assert_selector "td[id='#{sample34.id}_metadata_2'] input[type='text']", text: ''
      assert_selector "td[id='#{sample35.id}_metadata_2'] input[type='text']", text: ''

      # change metadata_1 and metadata_2 option selection
      select 'metadatafield1', from: 'metadata_1'
      select 'metadatafield2', from: 'metadata_2'
      ### ACTIONS END ###

      ### VERIFY START ###
      # check new metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadatafield1'
      assert_selector '#field-metadata_2', text: 'metadatafield2'

      # check metadata values of samples
      assert_selector "td[id='#{sample32.id}_metadata_1'] span", text: sample32.metadata['metadatafield1']
      assert_selector "td[id='#{sample33.id}_metadata_1'] span", text: sample32.metadata['metadatafield1']
      assert_selector "td[id='#{sample34.id}_metadata_1'] span", text: sample32.metadata['metadatafield1']
      # sample contains no metadata value for this field, stays as text input
      assert_selector "td[id='#{sample35.id}_metadata_1'] input[type='text']", text: ''

      assert_selector "td[id='#{sample32.id}_metadata_2'] span", text: sample32.metadata['metadatafield2']
      assert_selector "td[id='#{sample33.id}_metadata_2'] span", text: sample32.metadata['metadatafield2']
      assert_selector "td[id='#{sample34.id}_metadata_2'] span", text: sample32.metadata['metadatafield2']
      # sample contains no metadata value for this field, stays as text input
      assert_selector "td[id='#{sample35.id}_metadata_2'] input[type='text']", text: ''
      ### VERIFY END ###
    end

    test 'samplesheet metadata header changes param value after workflow submission' do
      ### SETUP START ###
      user = users(:john_doe)
      namespace = groups(:group_twelve)
      sample32 = samples(:sample32)
      login_as user

      visit group_samples_url(namespace)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: user.locale))
      # select samples
      check "checkbox_sample_#{sample32.id}"

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/gasclustering'
      click_button 'phac-nml/gasclustering'
      ### SETUP END ###

      ### ACTIONS START ###
      assert_selector 'h1', text: 'phac-nml/gasclustering'

      find('input#workflow_execution_name').fill_in with: "WE-#{sample32.name}"

      # check default metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadata_1'
      assert_selector '#field-metadata_8', text: 'metadata_8'

      # change metadata_1 and metadata_8 option selection
      select 'metadatafield1', from: 'metadata_1'
      select 'metadatafield2', from: 'metadata_8'

      # check new metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadatafield1'
      assert_selector '#field-metadata_8', text: 'metadatafield2'

      # submit pipeline
      click_button I18n.t(:'workflow_executions.submissions.create.submit')

      # verify redirection to workflow executions page
      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      # click the submitted workflow execution from above
      find('table tbody tr:first-child th:first-child a').click

      # verify show page
      assert_selector 'h1', text: "WE-#{sample32.name}"

      assert_text I18n.t(:'workflow_executions.show.tabs.params')
      # click parameters tab
      click_button I18n.t(:'workflow_executions.show.tabs.params')
      ### ACTIONS END ###

      ### VERIFY START ###
      # verify new parameter values
      assert_selector '.metadata_1_header-param input[disabled][value="metadatafield1"]'
      assert_no_selector '.metadata_1_header-param input[disabled][value="metadata_1"]'

      assert_selector '.metadata_8_header-param input[disabled][value="metadatafield2"]'
      assert_no_selector '.metadata_8_header-param input[disabled][value="metadata_8"]'
      ### VERIFY END ###
    end

    test 'analyst cannot update samples with analysis result' do
      user = users(:michelle_doe)
      login_as user

      project = projects(:project1)
      sample = samples(:sample1)
      Project.reset_counters(project.id, :samples_count)

      visit namespace_project_samples_url(project.namespace.parent, project)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{sample.id}"
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 1
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: sample.puid, count: 1
      assert_text I18n.t('components.nextflow.unauthorized_to_update_samples')
    end

    test 'cannot update shared samples with analysis results when shared role is analyst' do
      group = groups(:subgroup_sample_actions)
      user = users(:subgroup_sample_actions_doe)
      sample = samples(:sample71)

      login_as user

      visit group_samples_url(group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 5, count: 5,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{sample.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 1
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: sample.puid, count: 1

      assert_text I18n.t('components.nextflow.unauthorized_to_update_samples')
    end
  end
end
