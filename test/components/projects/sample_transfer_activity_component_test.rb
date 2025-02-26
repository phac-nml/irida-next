# frozen_string_literal: true

require 'view_component_test_case'

module Projects
  class SampleTransferActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'sample transfer source project actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.transfer')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
      end

      render_inline Activities::Projects::SampleTransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.samples.transfer_html',
          user: 'System',
          href: activity_to_render[:target_project_puid],
          transferred_samples_count: activity_to_render[:transferred_samples_ids]&.size
        )
      )

      assert_selector 'a',
                      text: activity_to_render[:target_project_puid]
    end

    test 'sample transfer target project actvity' do
      project_namespace = namespaces_project_namespaces(:project2_namespace)

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.transferred_from')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.transferred_from_html'
      end

      render_inline Activities::Projects::SampleTransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.samples.transferred_from_html',
          user: 'System',
          href: activity_to_render[:source_project_puid],
          transferred_samples_count: activity_to_render[:transferred_samples_ids]&.size
        )
      )

      assert_selector 'a',
                      text: activity_to_render[:source_project_puid]
    end

    test 'sample transfer source project deleted actvity' do
      project_namespace = namespaces_project_namespaces(:project2_namespace)
      project1 = projects(:project1)

      project1.really_destroy!

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.transferred_from')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.transferred_from_html'
      end

      render_inline Activities::Projects::SampleTransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.samples.transferred_from_html',
          user: 'System',
          href: activity_to_render[:source_project_puid],
          transferred_samples_count: activity_to_render[:transferred_samples_ids]&.size
        )
      )

      assert_selector 'a[disabled="disabled"]',
                      text: activity_to_render[:source_project_puid]
    end

    test 'sample transfer target project deleted actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      project2 = projects(:project2)

      project2.really_destroy!

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.transfer')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
      end

      render_inline Activities::Projects::SampleTransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.samples.transfer_html',
          user: 'System',
          href: activity_to_render[:target_project_puid],
          transferred_samples_count: activity_to_render[:transferred_samples_ids]&.size
        )
      )

      assert_selector 'a[disabled="disabled"]',
                      text: activity_to_render[:target_project_puid]
    end
  end
end
