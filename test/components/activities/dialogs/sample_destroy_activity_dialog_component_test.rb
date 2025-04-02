# frozen_string_literal: true

require 'view_component_test_case'

module Activities
  module Dialogs
    class SampleDestroyActivityDialogComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
      end

      test 'sample transfer activity dialog' do
        project_namespace = namespaces_project_namespaces(:project1_namespace)
        sample = samples(:sample1)
        params = { sample_ids: [sample.id] }
        ::Samples::DestroyService.new(project_namespace.project, @user, params).execute

        activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('project_namespace.samples.destroy_multiple')
        end)

        @activity_owner = @user.email

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
        end

        activity_to_render = PublicActivity::Activity.find(activity_to_render[:id])

        render_inline Activities::Dialogs::SampleDestroyActivityDialogComponent.new(activity: activity_to_render,
                                                                                    activity_owner: @activity_owner)

        assert_selector 'h1', text: I18n.t(:'components.activity.dialog.sample_destroy.title')

        assert_selector 'p',
                        text: I18n.t(:'components.activity.dialog.sample_destroy.description',
                                     user: @user.email, count: 1)

        assert_selector 'li', count: 1
        assert_selector 'li', text: 'INXT_SAM_AAAAAAAAAA'
      end
    end
  end
end
