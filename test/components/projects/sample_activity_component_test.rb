# frozen_string_literal: true

require 'view_component_test_case'

module Projects
  class SampleActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'sample create actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
      sample = samples(:sample1)

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.create_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.create_html', user: 'System',
                                                                            href: sample.puid)
      )
      assert_selector 'a',
                      text: sample.puid
    end

    test 'sample update actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)

      valid_params = { name: 'new-sample1-name', description: 'new-sample1-description' }
      ::Samples::UpdateService.new(sample, @user, valid_params).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.update_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.update_html', user: @user.email,
                                                                            href: sample.puid)
      )
      assert_selector 'a',
                      text: sample.puid
    end

    test 'sample update and permanently destroy actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)

      valid_params = { name: 'new-sample1-name', description: 'new-sample1-description' }
      ::Samples::UpdateService.new(sample, @user, valid_params).execute

      params = { sample: sample }
      ::Samples::DestroyService.new(project_namespace.project, @user, params).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.update_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.update_html', user: @user.email,
                                                                            href: sample.puid)
      )
      assert_selector 'a[disabled="disabled"]',
                      text: sample.puid
    end

    test 'single sample destroy activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)

      params = { sample: sample }
      ::Samples::DestroyService.new(project_namespace.project, @user, params).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.destroy_html')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.destroy_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.destroy_html', user: @user.email,
                                                                             href: sample.puid)
      )
      assert_selector 'a[disabled="disabled"]',
                      text: sample.puid
    end

    test 'multiple sample destroy activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)

      params = { sample_ids: [sample1.id, sample2.id] }
      ::Samples::DestroyService.new(project_namespace.project, @user, params).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.destroy_multiple')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.destroy_multiple_html', user: @user.email,
                                                                                      href: 2)
      )
      assert_selector 'a[disabled="disabled"]', text: 2
    end

    test 'sample metadata update activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)

      params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
      ::Samples::Metadata::UpdateService.new(project_namespace.project, sample, @user, params).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.metadata.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.metadata.update_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.metadata.update_html', user: @user.email,
                                                                                     href: sample.puid)
      )

      assert_selector 'a',
                      text: sample.puid
    end

    test 'sample attachment create activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
      sample = samples(:sample1)

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.attachment.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.attachment.create_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.attachment.create_html', user: 'System',
                                                                                       href: sample.puid)
      )
      assert_selector 'a',
                      text: sample.puid
    end

    test 'sample attachment destroy activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)
      attachment = attachments(:attachment1)

      ::Attachments::DestroyService.new(sample, attachment, @user).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.attachment.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.attachment.destroy_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.attachment.destroy_html', user: @user.email,
                                                                                        href: sample.puid)
      )
      assert_selector 'a',
                      text: sample.puid
    end

    test 'sample attachment destroy and permanently delete sample activity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      sample = samples(:sample1)
      attachment = attachments(:attachment1)

      ::Attachments::DestroyService.new(sample, attachment, @user).execute

      ::Samples::DestroyService.new(project_namespace.project, @user, { sample: sample }).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.samples.attachment.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.samples.attachment.create_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.samples.attachment.create_html', user: 'System',
                                                                                       href: sample.puid)
      )
      assert_selector 'a[disabled="disabled"]',
                      text: sample.puid
    end

    test 'batch sample import actvity' do
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.import_samples.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.import_samples.create_html'
      end

      render_inline Activities::Projects::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.import_samples.create_html',
               user: 'System',
               href: 2)
      )
      assert_selector 'a',
                      text: 2
    end
  end
end
