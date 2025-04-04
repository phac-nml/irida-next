# frozen_string_literal: true

require 'view_component_test_case'

module Activities
  module Dialogs
    class SampleTransferActivityDialogComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
      end

      test 'sample transfer activity dialog source project' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.transfer')
        end)

        @activity_owner = I18n.t('activerecord.concerns.track_activity.system')

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::SampleTransferActivityDialogComponent.new(activity: activity_to_render,
                                                                                     activity_owner: @activity_owner)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_transfer.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_transfer.target_project_description',
                                     user: 'System', count: 1,
                                     target_project_puid: 'INXT_PRJ_AAAAAAAAAB')

        assert_selector 'li', count: 1
        assert_selector 'li', text: 'INXT_SAM_AAAAAAAAAA'
      end

      test 'sample transfer activity dialog target project' do
        project_namespace = namespaces_project_namespaces(:project2_namespace)

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.transferred_from')
        end)

        @activity_owner = I18n.t('activerecord.concerns.track_activity.system')

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.transferred_from_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::SampleTransferActivityDialogComponent.new(activity: activity_to_render,
                                                                                     activity_owner: @activity_owner)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_transfer.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_transfer.source_project_description',
                                     user: 'System', count: 1,
                                     source_project_puid: 'INXT_PRJ_AAAAAAAAAA')

        assert_selector 'li', count: 1
        assert_selector 'li', text: 'INXT_SAM_AAAAAAAAAA'
      end
    end
  end
end
