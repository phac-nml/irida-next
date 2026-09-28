# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  include ActionView::Helpers::SanitizeHelper

  def setup
    @user = users(:john_doe)
    @group1 = groups(:group_one)
    @group5 = groups(:group_five)
    @project1 = projects(:project1)
    @sample1 = samples(:sample1)
    @sample30 = samples(:sample30)
    @workflow_execution1 = workflow_executions(:irida_next_example_completed_with_output)
    @group_shared_workflow_execution1 = workflow_executions(:workflow_execution_completed_group_shared1)

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

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
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

    click_button I18n.t('shared.samples.actions_dropdown.label')
    assert_no_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
    assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.linelist_export')
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

  test 'create export link on user workflow executions index page state changes based on selection' do
    visit workflow_executions_path

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    assert_selector 'button[disabled]',
                    text: I18n.t('shared.workflow_executions.actions_dropdown.create_export')

    within %(#workflow-executions-table) do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
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
    end
  end

  test 'can view samples selected for data export' do
    # Group samples page
    visit group_samples_path(@group1)
    assert_selector "input[type='checkbox'][value='#{@sample1.id}']", count: 1
    find("input[type='checkbox'][value='#{@sample1.id}']").click
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new.sample_description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
      end
    end

    # Project samples page
    visit namespace_project_samples_path(@group1, @project1)

    assert_selector "input[type='checkbox'][value='#{@sample1.id}']", count: 1
    find("input[type='checkbox'][value='#{@sample1.id}']").click
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'

      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.after_submission_description_html')
      )
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
      end
    end
  end

  test 'can view workflow executions selected for data export' do
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
      click_button I18n.t('data_exports.new_analysis_export_dialog.selection_count.non_zero').gsub! 'COUNT_PLACEHOLDER',
                                                                                                    '1'
      assert_text I18n.t('data_exports.new_analysis_export_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(I18n.t('data_exports.new.after_submission_description_html'))
      within %(turbo-frame[id="list_selections"]) do
        assert_text @group_shared_workflow_execution1.id
        assert_text @group_shared_workflow_execution1.workflow.name
        assert_text @group_shared_workflow_execution1.workflow.version
      end
    end
  end
end
