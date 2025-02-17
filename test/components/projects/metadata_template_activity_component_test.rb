# frozen_string_literal: true

require 'view_component_test_case'

module Projects
  class MetadataTemplateActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @user.namespace.id } }
      @project ||= Projects::CreateService.new(@user, valid_params).execute
      params = { name: 'test template', fields: %w[a b c] }
      @template ||= MetadataTemplates::CreateService.new(@user, @project.namespace, params).execute
    end
    test 'add template activity' do
      template = metadata_templates(:valid_metadata_template)
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.metadata_template.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.metadata_template.create_html'
      end

      render_inline Activities::Projects::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.metadata_template.create_html', user: 'System',
                                                                                      href: template.name)
      )
      assert_selector 'a',
                      text: template.name
    end

    test 'update template activity' do
      template = metadata_templates(:valid_metadata_template)
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      params = { name: 'Valid Template Updated' }

      MetadataTemplates::UpdateService.new(
        @user, template, params
      ).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.metadata_template.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.metadata_template.update_html'
      end

      render_inline Activities::Projects::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.metadata_template.update_html', user: @user.email,
                                                                                      href: template.name)
      )
      assert_selector 'a', text: template.name
    end

    test 'update template then destroy permanently activity' do
      template = metadata_templates(:valid_metadata_template)
      project_namespace = namespaces_project_namespaces(:project1_namespace)
      params = { name: 'Valid Template Updated' }

      MetadataTemplates::UpdateService.new(
        @user, template, params
      ).execute

      # Permanently destroyed
      MetadataTemplate.find_by(id: template.id).really_destroy!

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.metadata_template.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.metadata_template.update_html'
      end

      render_inline Activities::Projects::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.metadata_template.update_html', user: @user.email,
                                                                                      href: template.name)
      )
      assert_no_selector 'a', text: template.name
    end

    test 'soft deleted template activity' do
      template = metadata_templates(:valid_metadata_template)
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      MetadataTemplates::DestroyService.new(
        @user, template
      ).execute

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.metadata_template.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.metadata_template.destroy_html'
      end

      render_inline Activities::Projects::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.metadata_template.destroy_html', user: @user.email,
                                                                                       template_name: template.name)
      )

      assert_no_selector 'a', text: @template.name
    end

    test 'permanently deleted template activity' do
      template = metadata_templates(:valid_metadata_template)
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      MetadataTemplates::DestroyService.new(
        @user, template
      ).execute

      MetadataTemplate.only_deleted.find_by(id: template.id).really_destroy!

      activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse
      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.metadata_template.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.metadata_template.destroy_html'
      end

      render_inline Activities::Projects::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.namespaces_project_namespace.metadata_template.destroy_html', user: @user.email,
                                                                                       template_name: template.name)
      )

      assert_no_selector 'a', text: @template.name
    end
  end
end
