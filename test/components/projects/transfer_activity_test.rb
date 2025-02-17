# frozen_string_literal: true

require 'view_component_test_case'

module Projects
  class TransferActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'sample transfer old namespace actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.transfer')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.transfer_html'
      end

      render_inline Activities::Projects::TransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.transfer_html',
          user: 'System',
          old_namespace: activity_to_render[:old_namespace],
          new_namespace: activity_to_render[:new_namespace]
        )
      )

      assert_no_selector 'a'
    end
  end
end
