# frozen_string_literal: true

require 'view_component_test_case'

module Activities
  module Dialogs
    class SampleCloneActivityDialogComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
      end

      test 'sample clone activity dialog source project' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.clone')
        end)

        @activity_owner = I18n.t('activerecord.concerns.track_activity.system')

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.clone_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::SampleCloneActivityDialogComponent.new(activity: activity_to_render,
                                                                                  activity_owner: @activity_owner)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_clone.target_project_description',
                                     user: 'System', count: 1,
                                     target_project_puid: 'INXT_PRJ_AAAAAAAAAB')
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from')
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to')
        assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
      end

      test 'sample clone activity dialog target project' do
        project_namespace = namespaces_project_namespaces(:project2_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.cloned_from')
        end)

        @activity_owner = I18n.t('activerecord.concerns.track_activity.system')

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.cloned_from_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::SampleCloneActivityDialogComponent.new(activity: activity_to_render,
                                                                                  activity_owner: @activity_owner)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_clone.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_clone.source_project_description',
                                     user: 'System', count: 1,
                                     source_project_puid: 'INXT_PRJ_AAAAAAAAAA')
        assert_selector 'table', count: 1
        assert_selector 'th', count: 2
        assert_selector 'tr', count: 2
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_from')
        assert_selector 'tr > th', text: I18n.t(:'components.activity.dialog.sample_clone.copied_to')
        assert_selector 'tr > td', text: 'INXT_SAM_AAAAAAAAAA'
        assert_selector 'tr > td', text: 'INXT_SAM_XAAAATAAAA'
      end
    end
  end
end
