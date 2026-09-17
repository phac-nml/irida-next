# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  include ActionView::Helpers::SanitizeHelper

  def setup # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @user = users(:john_doe)
    @data_export1 = data_exports(:data_export_one)
    @data_export2 = data_exports(:data_export_two)
    @data_export6 = data_exports(:data_export_six)
    @data_export7 = data_exports(:data_export_seven)
    @data_export8 = data_exports(:data_export_eight)
    @data_export9 = data_exports(:data_export_nine)
    @data_export10 = data_exports(:data_export_ten)
    @group1 = groups(:group_one)
    @group5 = groups(:group_five)
    @project1 = projects(:project1)
    @project22 = projects(:project22)
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @sample30 = samples(:sample30)
    @sample47 = samples(:sample47)
    @workflow_execution1 = workflow_executions(:irida_next_example_completed_with_output)
    @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    @workflow_execution3 = workflow_executions(:irida_next_example_error)
    @workflow_execution4 = workflow_executions(:automated_workflow_execution)
    @workflow_execution5 = workflow_executions(:automated_example_error)
    @shared_workflow_execution1 = workflow_executions(:workflow_execution_completed_shared1)
    @shared_workflow_execution2 = workflow_executions(:workflow_execution_completed_shared2)
    @group_shared_workflow_execution1 = workflow_executions(:workflow_execution_completed_group_shared1)
    @group_shared_workflow_execution2 = workflow_executions(:workflow_execution_completed_group_shared2)

    Project.reset_counters(@project1.id, :samples_count)

    login_as @user
  end

  test 'checking off samples on different page does not affect current page\'s export samples' do
    subgroup12a = groups(:subgroup_twelve_a)
    project29 = projects(:project29)
    Project.reset_counters(project29.id, :samples_count)
    sample32 = samples(:sample32)

    visit namespace_project_samples_url(subgroup12a, project29)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample32.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.sample_export')

    visit namespace_project_samples_url(@group1, @project1)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_selector 'button',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export')

    click_button I18n.t('shared.samples.actions_dropdown.sample_export')

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
      end
      assert_text I18n.t('data_exports.new.sample_description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
    end
  end

  test 'clicking links in preview tab for analysis data export' do
    visit data_export_path(@data_export7)
    click_button I18n.t('data_exports.show.tabs.preview')

    click_link @workflow_execution1.id

    assert_current_path(workflow_execution_path(@workflow_execution1))

    click_button I18n.t('workflow_executions.show.create_export_button')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection')
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_text @workflow_execution1.id
      assert_text @workflow_execution1.run_id
      assert_text @workflow_execution1.workflow.name
      assert_text @workflow_execution1.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export using users project shared workflow execution from user workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit workflow_execution_path(@shared_workflow_execution1)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @shared_workflow_execution1.id
      assert_text @shared_workflow_execution1.run_id
      assert_text @shared_workflow_execution1.workflow.name
      assert_text @shared_workflow_execution1.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export using users group shared workflow execution from user workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit workflow_execution_path(@group_shared_workflow_execution1)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @group_shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @group_shared_workflow_execution1.id
      assert_text @group_shared_workflow_execution1.run_id
      assert_text @group_shared_workflow_execution1.workflow.name
      assert_text @group_shared_workflow_execution1.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export using users shared workflow execution from project workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit namespace_project_workflow_execution_path(@group5, @project22, @shared_workflow_execution1)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @shared_workflow_execution1.id
      assert_text @shared_workflow_execution1.run_id
      assert_text @shared_workflow_execution1.workflow.name
      assert_text @shared_workflow_execution1.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export using users group shared workflow execution from group workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit group_workflow_execution_path(@group5, @group_shared_workflow_execution1)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @group_shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @group_shared_workflow_execution1.id
      assert_text @group_shared_workflow_execution1.run_id
      assert_text @group_shared_workflow_execution1.workflow.name
      assert_text @group_shared_workflow_execution1.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export from project shared workflow execution from project workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit namespace_project_workflow_execution_path(@group5, @project22, @shared_workflow_execution2)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @shared_workflow_execution2.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @shared_workflow_execution2.id
      assert_text @shared_workflow_execution2.run_id
      assert_text @shared_workflow_execution2.workflow.name
      assert_text @shared_workflow_execution2.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export from group shared workflow execution from group workflow execution show page' do
    user = users(:james_doe)
    login_as user
    visit group_workflow_execution_path(@group5, @group_shared_workflow_execution2)
    click_button I18n.t('workflow_executions.show.tabs.summary', locale: user.locale)

    click_button I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @group_shared_workflow_execution2.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )

      click_button I18n.t('data_exports.new_single_analysis_export_dialog.single_selection', locale: user.locale)
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_text @group_shared_workflow_execution2.id
      assert_text @group_shared_workflow_execution2.run_id
      assert_text @group_shared_workflow_execution2.workflow.name
      assert_text @group_shared_workflow_execution2.metadata['workflow_version']

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'clicking links in preview tab for analysis data export from user shared workflow execution' do
    login_as users(:micha_doe)
    data_export11 = data_exports(:data_export_eleven)
    visit data_export_path(data_export11)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:micha_doe).locale)

    click_link @shared_workflow_execution2.id

    assert_current_path(workflow_execution_path(@shared_workflow_execution2))
    assert_text @shared_workflow_execution2.id

    within first('dl') do
      assert_text @shared_workflow_execution2.run_id
      assert_text @shared_workflow_execution2.workflow.name
      assert_text @shared_workflow_execution2.metadata['workflow_version']
    end

    visit data_export_path(data_export11)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:micha_doe).locale)

    click_link @sample47.puid

    assert_text @sample47.name
    assert_text @sample47.puid
  end

  test 'clicking links in preview tab for analysis data export from project shared workflow execution' do
    login_as users(:james_doe)
    data_export12 = data_exports(:data_export_twelve)
    visit data_export_path(data_export12)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:james_doe).locale)

    click_link @shared_workflow_execution2.id

    assert_current_path(namespace_project_workflow_execution_path(@group5, @project22, @shared_workflow_execution2))
    assert_text @shared_workflow_execution2.id

    assert_text @shared_workflow_execution2.run_id
    assert_text @shared_workflow_execution2.workflow.name
    assert_text @shared_workflow_execution2.metadata['workflow_version']

    visit data_export_path(data_export12)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:james_doe).locale)

    click_link @sample47.puid

    assert_text @sample47.name
    assert_text @sample47.puid
  end

  test 'clicking links in preview tab for analysis data export from group shared workflow execution' do
    login_as users(:james_doe)
    data_export13 = data_exports(:data_export_thirteen)
    visit data_export_path(data_export13)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:james_doe).locale)

    click_link @group_shared_workflow_execution2.id

    assert_current_path(group_workflow_execution_path(@group5, @group_shared_workflow_execution2))
    assert_text @group_shared_workflow_execution2.id

    within first('dl') do
      assert_text @group_shared_workflow_execution2.run_id
      assert_text @group_shared_workflow_execution2.workflow.name
      assert_text @group_shared_workflow_execution2.metadata['workflow_version']
    end

    visit data_export_path(data_export13)
    click_button I18n.t('data_exports.show.tabs.preview', locale: users(:james_doe).locale)

    click_link @sample47.puid

    assert_text @sample47.name
    assert_text @sample47.puid
  end

  test 'projects with samples containing no metadata should have linelist export link enabled' do
    project = projects(:project2)
    Project.reset_counters(project.id, :samples_count)
    sample3 = samples(:sample3)

    visit namespace_project_samples_url(@group1, project)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample3.id}']").click
    end

    assert_no_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new.sample_description.singular')

      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text sample3.name
        assert_text sample3.puid
      end

      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'

      assert_no_selector 'button[aria-disabled="true"]',
                         text: I18n.t('data_exports.new.submit_button')
    end
  end

  test 'groups with samples containing no metadata should have linelist export link enabled' do
    group = groups(:group_sixteen)
    sample43 = samples(:sample43)

    visit group_samples_url(group)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample43.id}']").click
    end

    assert_no_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new.sample_description.singular')

      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text sample43.name
        assert_text sample43.puid
      end

      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'

      assert_no_selector 'input[disabled]' # submit button enabled
    end
  end

  test 'new linelist export dialog' do
    visit namespace_project_samples_url(@group1, @project1)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_linelist_export_dialog.title')
      assert_text I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new_linelist_export_dialog.metadata')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.fields_instructions')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.available_list_title')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.selected_list_title')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.format')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.csv')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.xlsx')
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @sample30.name
      assert_no_text @sample30.puid
      assert_no_text I18n.t('data_exports.new.sample_description.singular')

      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new.sample_description.singular')

      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample30.name
        assert_text @sample30.puid
      end

      within 'ul#available-list' do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within 'ul#selected-list' do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end
    end
  end

  test 'sortable list buttons in new linelist export dialog' do
    visit namespace_project_samples_url(@group1, @project1)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      within 'ul#available-list' do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within 'ul#selected-list' do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end

      # all buttons disabled
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')

      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'metadatafield1').click

      # after 1 selection, add button enabled; remove, up and down buttons still disabled
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'metadatafield2').click
      click_button I18n.t('components.sortable_lists.v1.list_component.add')

      within 'ul#selected-list' do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within 'ul#available-list' do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end

      # submit no longer disabled
      assert_no_selector 'button[aria-disabled="true"]',
                         text: I18n.t('data_exports.new.submit_button')

      # all buttons disabled again
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'metadatafield1').click
      # after 1 selection, remove, and down buttons enabled; add and up still disabled (up disabled because top option
      # is selected)
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')

      # click down button to move selected option to bottom, verify up is now enabled and down is disabled
      click_button I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      find('li', exact_text: 'metadatafield2').click
      # after 2 selections, up and down are now disabled
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      click_button I18n.t('common.actions.remove')

      within 'ul#available-list' do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within 'ul#selected-list' do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end
    end
  end

  test 'create csv export from project samples page' do
    visit namespace_project_samples_url(@group1, @project1)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within('tbody') do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      find('li', exact_text: 'metadatafield1').click
      find('li', exact_text: 'metadatafield2').click
      click_button I18n.t('components.sortable_lists.v1.list_component.add')
      find('input#data_export_name').fill_in with: 'test csv export'
      click_button I18n.t('data_exports.new.submit_button')
    end

    within('dl') do
      assert_selector 'div:nth-child(2) dd', text: 'test csv export'
      assert_selector 'div:nth-child(4) dd', text: 'csv'
    end
  end

  test 'create xlsx export from group samples page' do
    visit group_samples_url(@group1)
    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    within('tbody') do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.samples.actions_dropdown.linelist_export')

    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      find('li', exact_text: 'metadatafield1').click
      find('li', exact_text: 'metadatafield2').click
      click_button I18n.t('components.sortable_lists.v1.list_component.add')
      find('input#data_export_name').fill_in with: 'test xlsx export'
      find('input#xlsx-format').click
      click_button I18n.t('data_exports.new.submit_button')
    end

    within('dl') do
      assert_selector 'div:nth-child(2) dd', text: 'test xlsx export'
      assert_selector 'div:nth-child(4) dd', text: 'xlsx'
    end
  end

  test 'sortable list buttons in new_sample_export_dialog' do
    visit namespace_project_samples_url(@group1, @project1)

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.sample_export'), match: :first

    within 'dialog[open].dialog--size-lg' do
      within '#available-list' do
        assert_selector 'li', count: 10
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end
      within '#selected-list' do
        assert_no_selector 'li'
      end

      assert_button I18n.t('data_exports.new.submit_button'), disabled: true

      find('li', exact_text: 'csv').click
      find('li', exact_text: 'json').click

      click_button I18n.t('components.sortable_lists.v1.list_component.add')

      within '#selected-list' do
        assert_selector 'li', count: 2
      end
      within '#available-list' do
        assert_selector 'li', count: 8
      end
      # all buttons disabled again
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'csv').click
      # after 1 selection, remove and down buttons enabled; add and up (first option, can't move up) still disabled
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'json').click
      # after 2 selections, up and down are now disabled
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      click_button I18n.t('common.actions.remove')

      within '#selected-list' do
        assert_selector 'li', count: 0
      end
      within '#available-list' do
        assert_selector 'li', count: 10
      end

      # all buttons disabled
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')

      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'json').click

      # after 1 selection, add button enabled; remove, up and down buttons still disabled
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
      assert_selector 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')
      assert_selector 'button[aria-disabled="false"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
      find('li', exact_text: 'csv').click
      click_button I18n.t('components.sortable_lists.v1.list_component.add')

      within '#available-list' do
        assert_selector 'li', count: 8
      end
      within '#selected-list' do
        assert_selector 'li', count: 2
        assert_selector 'li', exact_text: 'csv'
        assert_selector 'li', exact_text: 'json'
      end
    end
  end

  test 'new analysis export with multiple workflow executions from user workflow executions index page' do
    visit workflow_executions_path

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution2.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '2'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @workflow_execution1.id
      assert_no_text @workflow_execution2.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '2'
      assert_text  I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @workflow_execution1.id
        assert_text @workflow_execution1.run_id
        assert_text @workflow_execution1.workflow.name
        assert_text @workflow_execution1.metadata['workflow_version']
        assert_text @workflow_execution2.id
        assert_text @workflow_execution2.run_id
        assert_text @workflow_execution2.workflow.name
        assert_text @workflow_execution2.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'new analysis export with single workflow execution from project workflow executions index page' do
    visit namespace_project_workflow_executions_path(@group1, @project1)

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '1'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @workflow_execution4.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '1'
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @workflow_execution4.id
        assert_text @workflow_execution4.run_id
        assert_text @workflow_execution4.workflow.name
        assert_text @workflow_execution4.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export with a workflow execution from user workflow executions index page' do
    user = users(:james_doe)
    login_as user
    visit workflow_executions_path

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label', locale: user.locale)
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@shared_workflow_execution1.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label', locale: user.locale)
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t(
        'data_exports.new_analysis_export_dialog.selection_count.non_zero', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      click_button I18n.t(
        'data_exports.new_analysis_export_dialog.selection_count.non_zero', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular', locale: user.locale)
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @shared_workflow_execution1.id
        assert_text @shared_workflow_execution1.run_id
        assert_text @shared_workflow_execution1.workflow.name
        assert_text @shared_workflow_execution1.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export with multiple shared workflow executions from project workflow executions index page' do
    user = users(:james_doe)
    login_as user
    visit namespace_project_workflow_executions_path(@group5, @project22)

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label', locale: user.locale)
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@shared_workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@shared_workflow_execution2.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label', locale: user.locale)
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export', locale: user.locale)

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      assert_text I18n.t(
        'data_exports.new_analysis_export_dialog.selection_count.non_zero', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text I18n.t('data_exports.new.name_label', locale: user.locale)
      assert_text I18n.t('data_exports.new.email_label', locale: user.locale)

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @shared_workflow_execution1.id
      assert_no_text @shared_workflow_execution2.id
      assert_no_text I18n.t(
        'data_exports.new_analysis_export_dialog.description.plural', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '2'
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      click_button I18n.t(
        'data_exports.new_analysis_export_dialog.selection_count.non_zero', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text I18n.t(
        'data_exports.new_analysis_export_dialog.description.plural', locale: user.locale
      ).gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html', locale: user.locale)
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @shared_workflow_execution1.id
        assert_text @shared_workflow_execution1.run_id
        assert_text @shared_workflow_execution1.workflow.name
        assert_text @shared_workflow_execution1.metadata['workflow_version']
        assert_text @shared_workflow_execution2.id
        assert_text @shared_workflow_execution2.run_id
        assert_text @shared_workflow_execution2.workflow.name
        assert_text @shared_workflow_execution2.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button', locale: user.locale)
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'new analysis export with single workflow execution from group workflow executions index page' do
    login_as users(:micha_doe)
    visit group_workflow_executions_path(@group5)

    assert_selector 'button[disabled]',
                    text: I18n.t('groups.workflow_executions.index.create_export_button')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@group_shared_workflow_execution1.id}']").click
    end

    assert_no_selector 'button[disabled]',
                       text: I18n.t('groups.workflow_executions.index.create_export_button')
    click_button I18n.t('groups.workflow_executions.index.create_export_button')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '1'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @group_shared_workflow_execution1.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '1'
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @group_shared_workflow_execution1.id
        assert_text @group_shared_workflow_execution1.run_id
        assert_text @group_shared_workflow_execution1.workflow.name
        assert_text @group_shared_workflow_execution1.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create analysis export with multiple shared workflow executions from group workflow executions index page' do
    login_as users(:micha_doe)
    visit group_workflow_executions_path(@group5)
    assert_selector 'button[disabled]',
                    text: I18n.t('groups.workflow_executions.index.create_export_button')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@group_shared_workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@group_shared_workflow_execution2.id}']").click
    end

    assert_no_selector 'button[disabled]',
                       text: I18n.t('groups.workflow_executions.index.create_export_button')
    click_button I18n.t('groups.workflow_executions.index.create_export_button')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '2'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @group_shared_workflow_execution1.id
      assert_no_text @group_shared_workflow_execution2.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '2'
      assert_text  I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @group_shared_workflow_execution1.id
        assert_text @group_shared_workflow_execution1.run_id
        assert_text @group_shared_workflow_execution1.workflow.name
        assert_text @group_shared_workflow_execution1.metadata['workflow_version']
        assert_text @group_shared_workflow_execution2.id
        assert_text @group_shared_workflow_execution2.run_id
        assert_text @group_shared_workflow_execution2.workflow.name
        assert_text @group_shared_workflow_execution2.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'cannot create analysis export with non-completed workflow executions from user WE index page' do
    visit workflow_executions_path

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution3.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '2'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @workflow_execution1.id
      assert_no_text @workflow_execution2.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '2'
      assert_text  I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @workflow_execution1.id
        assert_text @workflow_execution1.run_id
        assert_text @workflow_execution1.workflow.name
        assert_text @workflow_execution1.metadata['workflow_version']
        assert_text @workflow_execution3.id
        assert_text @workflow_execution3.run_id
        assert_text @workflow_execution3.workflow.name
        assert_text @workflow_execution3.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_text I18n.t('services.data_exports.create.non_completed_workflow_executions')
  end

  test 'cannot create analysis export with non-completed workflow execution from project WE index page' do
    visit namespace_project_workflow_executions_path(@group1, @project1)

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution5.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_no_selector 'button[disabled]',
                       text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_analysis_export_dialog.title')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                   '2'
      assert_text I18n.t('data_exports.new.name_label')
      assert_text I18n.t('data_exports.new.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @workflow_execution4.id
      assert_no_text I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '2'
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.plural').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @workflow_execution4.id
        assert_text @workflow_execution4.run_id
        assert_text @workflow_execution4.workflow.name
        assert_text @workflow_execution4.metadata['workflow_version']
        assert_text @workflow_execution5.id
        assert_text @workflow_execution5.run_id
        assert_text @workflow_execution5.workflow.name
        assert_text @workflow_execution5.metadata['workflow_version']
      end

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new.submit_button')
    end

    assert_text I18n.t('services.data_exports.create.non_completed_workflow_executions')
  end
end
