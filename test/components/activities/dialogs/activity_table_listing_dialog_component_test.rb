# frozen_string_literal: true

require 'application_system_test_case'

module Activities
  module Dialogs
    class ActivityTableListingDialogComponentTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
      end

      test 'sample clone activity dialog source project' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.clone')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.clone_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        load_more_button = find('button', text: 'Load more')
        click_button 'Load more' if load_more_button

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_clone.project.target_project_description',
                                       user: 'System', count: 1,
                                       target_project_puid: 'INXT_PRJ_AAAAAAAAAB')

          assert_selector 'table', count: 1
          assert_selector 'th', count: 2
          assert_selector 'tr', count: 2
          assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from').upcase
          assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to').upcase
          assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
          assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
        end
      end

      test 'sample clone activity dialog target project' do
        project_namespace = namespaces_project_namespaces(:project2_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.cloned_from')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.cloned_from_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_clone.project.source_project_description',
                                     user: 'System', count: 1,
                                     source_project_puid: 'INXT_PRJ_AAAAAAAAAA')
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to').upcase
        assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
      end

      test 'workflow execution destroy activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)
        workflow_execution = workflow_executions(:automated_example_canceled)
        ::WorkflowExecutions::DestroyService.new(@user,
                                                 { workflow_execution:,
                                                   namespace: project_namespace }).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(2, activities.count do |activity|
          activity[:key].include?('activity.namespaces_project_namespace.workflow_executions.destroy_html')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.workflow_executions.destroy_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                                     user: @user.email, count: 1)
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.name').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.workflow_execution_destroy.id').upcase
        assert_selector 'tr > td', text: workflow_execution.name
        assert_selector 'tr > td', text: workflow_execution.id
      end

      test 'group samples destroy activity dialog' do
        group_namespace = groups(:group_one)

        activities = group_namespace.human_readable_activity(group_namespace.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.samples.destroy')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.samples.destroy_html'
        end

        visit group_activity_path(group_namespace)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_destroy.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_destroy.description.group',
                                     user: 'System', count: 2)
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 3
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_destroy.sample').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_destroy.project').upcase
        assert_selector 'tr > td', text: 'sample 1 name'
        assert_selector 'tr > td', text: 'sample 1 puid'
        assert_selector 'tr > td', text: 'sample 2 name'
        assert_selector 'tr > td', text: 'sample 1 puid'
        assert_selector 'tr > td', text: 'INXT_PRJ_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_PRJ_AAAAAAAAAB'
        assert_selector 'tr > td', text: 'Project 1'
        assert_selector 'tr > td', text: 'Project 2'
      end

      test 'group import samples activity dialog' do
        group_namespace = groups(:group_one)

        activities = group_namespace.human_readable_activity(group_namespace.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.import_samples.create')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.import_samples.create_html'
        end

        visit group_activity_path(group_namespace)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.import_samples.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.import_samples.description.group',
                                     user: 'System', count: 2)
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 3
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.import_samples.sample').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.import_samples.project').upcase
        assert_selector 'tr > td', text: 'sample 1 name'
        assert_selector 'tr > td', text: 'sample 1 puid'
        assert_selector 'tr > td', text: 'sample 2 name'
        assert_selector 'tr > td', text: 'sample 1 puid'
        assert_selector 'tr > td', text: 'INXT_PRJ_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_PRJ_AAAAAAAAAB'
      end

      test 'group samples transfer activity dialog' do
        user = users(:mary_doe)
        login_as user
        group = groups(:group_sample_transfer)

        activities = group.human_readable_activity(group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.samples.transfer')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.samples.transfer_html'
        end

        visit group_activity_path(group)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.group_sample_transfer.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.group_sample_transfer.description',
                                       user: 'System', count: 3,
                                       target_project_puid: 'INXT_PRJ_AAAAAAAACD')

          assert_selector 'table', count: 1
          assert_selector 'th', count: 3
          assert_selector 'tr', count: 4
          assert_selector 'tr > th',
                          text: I18n.t(:'components.activity.dialog.group_sample_transfer.transferred_from').upcase
          assert_selector 'tr > th',
                          text: I18n.t(:'components.activity.dialog.group_sample_transfer.transferred_to').upcase

          assert_selector 'tr:nth-child(1) > td:first-child', text: 'Group Sample Transfer 1'
          assert_selector 'tr:nth-child(1) > td:first-child > span', text: 'INXT_SAM_AAAAAAAADQ'
          assert_selector 'tr:nth-child(1) > td:nth-child(2)', text: 'Project Group Sample Transfer'
          assert_selector 'tr:nth-child(1) > td:nth-child(2) > span', text: 'INXT_PRJ_AAAAAAAACC'
          assert_selector 'tr:nth-child(1) > td:nth-child(3)', text: 'Project Group Sample Transfer Target'
          assert_selector 'tr:nth-child(1) > td:nth-child(3) > span', text: 'INXT_PRJ_AAAAAAAACD'

          assert_selector 'tr:nth-child(2) > td:first-child', text: 'Group Sample Transfer 2'
          assert_selector 'tr:nth-child(2) > td:first-child > span', text: 'INXT_SAM_AAAAAAAADR'
          assert_selector 'tr:nth-child(2) > td:nth-child(2)', text: 'Project Group Sample Transfer'
          assert_selector 'tr:nth-child(2) > td:nth-child(2) > span', text: 'INXT_PRJ_AAAAAAAACC'
          assert_selector 'tr:nth-child(2) > td:nth-child(3)', text: 'Project Group Sample Transfer Target'
          assert_selector 'tr:nth-child(2) > td:nth-child(3) > span', text: 'INXT_PRJ_AAAAAAAACD'

          assert_selector 'tr:nth-child(3) > td:first-child', text: 'Group Sample Transfer 3'
          assert_selector 'tr:nth-child(3) > td:first-child > span', text: 'INXT_SAM_AAAAAAAADS'
          assert_selector 'tr:nth-child(3) > td:nth-child(2)', text: 'Project Group Sample Transfer'
          assert_selector 'tr:nth-child(3) > td:nth-child(2) > span', text: 'INXT_PRJ_AAAAAAAACC'
          assert_selector 'tr:nth-child(3) > td:nth-child(3)', text: 'Project Group Sample Transfer Target'
          assert_selector 'tr:nth-child(3) > td:nth-child(3) > span', text: 'INXT_PRJ_AAAAAAAACD'
        end
      end

      test 'group clone samples activity dialog' do
        group = groups(:group_one)
        project_namespace = namespaces_project_namespaces(:project2_namespace)
        project1 = projects(:project1)
        sample1 = samples(:sample1)
        sample2 = samples(:sample2)
        ::Groups::Samples::CloneService.new(group, @user)
                                       .execute(
                                         project_namespace.project.id,
                                         [sample1.id, sample2.id],
                                         nil
                                       )

        activities = group.human_readable_activity(group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.samples.clone')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.samples.clone_html'
        end

        visit group_activity_path(group)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_clone').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_clone.group.target_project_description',
                                     user: @user.email,
                                     count: activity_to_render[:cloned_samples_count])
        assert_selector 'table', count: 1
        assert_selector 'th', count: 4
        assert_selector 'tr', count: 3
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.project_from').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.project_to').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from').upcase
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to').upcase
        assert_selector 'tr > td', text: project1.name
        assert_selector 'tr > td', text: project1.puid, count: 2
        assert_selector 'tr > td', text: sample1.name, count: 2
        assert_selector 'tr > td', text: sample1.puid
        assert_selector 'tr > td', text: project_namespace.project.name, count: 2
        assert_selector 'tr > td', text: project_namespace.puid, count: 2
        assert_selector 'tr > td', text: sample2.name, count: 2
        assert_selector 'tr > td', text: sample2.puid
      end
    end
  end
end
