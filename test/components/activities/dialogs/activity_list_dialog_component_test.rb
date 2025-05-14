# frozen_string_literal: true

require 'application_system_test_case'

module Activities
  module Dialogs
    class ActivityListDialogComponentTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
      end

      test 'sample destroy activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)
        sample = samples(:sample1)
        params = { sample_ids: [sample.id] }
        ::Samples::DestroyService.new(project_namespace, @user, params).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.destroy_multiple')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_destroy').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_destroy.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_destroy.description',
                                       user: @user.email, count: 1)

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: 'Project 1 Sample 1'
          assert_selector 'li > p > span:nth-child(2)', text: 'INXT_SAM_AAAAAAAAAA'
        end
      end

      test 'sample transfer activity dialog source project' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.transfer')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_transfer').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_transfer.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_transfer.target_project_description',
                                       user: 'System', count: 1,
                                       target_project_puid: 'INXT_PRJ_AAAAAAAAAB')

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: 'Project 1 Sample 1'
          assert_selector 'li > p > span:nth-child(2)', text: 'INXT_SAM_AAAAAAAAAA'
        end
      end

      test 'sample transfer activity dialog target project' do
        project_namespace = namespaces_project_namespaces(:project2_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.transferred_from')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.transferred_from_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'samples_transfer').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_transfer.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_transfer.source_project_description',
                                       user: 'System', count: 1,
                                       source_project_puid: 'INXT_PRJ_AAAAAAAAAA')

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: 'Project 1 Sample 1'
          assert_selector 'li > p > span:nth-child(2)', text: 'INXT_SAM_AAAAAAAAAA'
        end
      end

      test 'project import samples activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('namespaces_project_namespace.import_samples.create')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.import_samples.create_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        load_more_button = find('button', text: 'Load more')
        click_button 'Load more' if load_more_button

        click_link(I18n.t('components.activity.more_details'),
                   href: activity_path(activity_to_render[:id], dialog_type: 'project_import_samples').to_s)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.import_samples.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.import_samples.description.project',
                                       user: 'System', count: 1)

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: 'sample name'
          assert_selector 'li > p > span:nth-child(2)', text: 'sample puid'
        end
      end
    end
  end
end
