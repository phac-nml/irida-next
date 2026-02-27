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
        ::Projects::Samples::DestroyService.new(project_namespace, @user, { sample_ids: [sample.id] }).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.destroy_multiple')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_destroy.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.sample_destroy.description.project',
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

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

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

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

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

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

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

      test 'project bulk sample metadata update activity dialog' do
        sample34 = samples(:sample34)
        sample35 = samples(:sample35)
        project_namespace = projects(:project31).namespace
        payload = { sample34.id => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' },
                    sample35.puid => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4]

        Samples::Metadata::BulkUpdateService.new(project_namespace, payload, metadata_fields, @user).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.bulk_metadata_update')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.bulk_metadata_update_html'
        end

        visit namespace_project_activity_path(project_namespace.parent, project_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.bulk_metadata_update.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.bulk_metadata_update.description',
                                       user: @user.email, count: 2)

          assert_selector 'li', count: 2
          assert_selector 'li > p > span:nth-child(1)', text: sample34.name
          assert_selector 'li > p > span:nth-child(2)', text: sample34.puid
          assert_selector 'li > p > span:nth-child(1)', text: sample35.name
          assert_selector 'li > p > span:nth-child(2)', text: sample35.puid
        end
      end

      test 'group level bulk sample metadata update produces activities updated project activity dialog' do
        group = groups(:group_twelve)
        sample33 = samples(:sample33)
        sample34 = samples(:sample34)
        sample35 = samples(:sample35)
        project30_namespace = projects(:project30).namespace
        project31_namespace = projects(:project31).namespace
        payload = { sample33.name => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' },
                    sample34.puid => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' },
                    sample35.id => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4]

        Samples::Metadata::BulkUpdateService.new(group, payload, metadata_fields, @user).execute

        # verify project 30 activity
        activities = project30_namespace.human_readable_activity(project30_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.bulk_metadata_update')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.bulk_metadata_update_html'
        end

        visit namespace_project_activity_path(project30_namespace.parent, project30_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.bulk_metadata_update.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.bulk_metadata_update.description',
                                       user: @user.email, count: 1)

          assert_selector 'li', count: 1
          assert_selector 'li > p > span:nth-child(1)', text: sample33.name
          assert_selector 'li > p > span:nth-child(2)', text: sample33.puid
        end

        # verify project 31 activity
        activities = project31_namespace.human_readable_activity(project31_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.bulk_metadata_update')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.bulk_metadata_update_html'
        end

        visit namespace_project_activity_path(project31_namespace.parent, project31_namespace.project)

        within("form[action='#{activity_path(activity_to_render[:id])}']") do
          click_button(I18n.t('components.activity.more_details'))
        end

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.bulk_metadata_update.title')

        within %(div[data-controller="activities--extended_details"][data-controller-connected="true"]) do
          assert_selector 'p',
                          text: I18n.t(:'components.activity.dialog.bulk_metadata_update.description',
                                       user: @user.email, count: 2)

          assert_selector 'li', count: 2
          assert_selector 'li > p > span:nth-child(1)', text: sample34.name
          assert_selector 'li > p > span:nth-child(2)', text: sample34.puid
          assert_selector 'li > p > span:nth-child(1)', text: sample35.name
          assert_selector 'li > p > span:nth-child(2)', text: sample35.puid
        end
      end
    end
  end
end
