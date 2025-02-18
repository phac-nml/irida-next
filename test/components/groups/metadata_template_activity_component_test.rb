# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class MetadataTemplateActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      valid_params = { name: 'newgroup', path: 'newgroup' }
      @group ||= Groups::CreateService.new(@user, valid_params).execute
      params = { name: 'test template', fields: %w[a b c] }
      @template ||= MetadataTemplates::CreateService.new(@user, @group, params).execute
    end
    test 'add template activity' do
      template = metadata_templates(:valid_group_metadata_template)
      group = groups(:group_one)
      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.metadata_template.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.metadata_template.create_html'
      end

      render_inline Activities::Groups::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.metadata_template.create_html', user: 'System',
                                                               href: template.name)
      )
      assert_selector 'a',
                      text: template.name
    end

    test 'update template activity' do
      template = metadata_templates(:valid_group_metadata_template)
      group = groups(:group_one)
      params = { name: 'Valid Group Template Updated' }

      MetadataTemplates::UpdateService.new(
        @user, template, params
      ).execute

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.metadata_template.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.metadata_template.update_html'
      end

      render_inline Activities::Groups::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.metadata_template.update_html', user: @user.email,
                                                               href: template.name)
      )
      assert_selector 'a', text: template.name
    end

    test 'update template then destroy permanently activity' do
      template = metadata_templates(:valid_group_metadata_template)
      group = groups(:group_one)
      params = { name: 'Valid Group Template Updated' }

      MetadataTemplates::UpdateService.new(
        @user, template, params
      ).execute

      # Permanently destroyed
      MetadataTemplate.find_by(id: template.id).really_destroy!

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.metadata_template.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.metadata_template.update_html'
      end

      render_inline Activities::Groups::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.metadata_template.update_html', user: @user.email,
                                                               href: template.name)
      )
      assert_no_selector 'a', text: template.name
    end

    test 'soft deleted template activity' do
      template = metadata_templates(:valid_group_metadata_template)
      group = groups(:group_one)

      MetadataTemplates::DestroyService.new(
        @user, template
      ).execute

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.metadata_template.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.metadata_template.destroy_html'
      end

      render_inline Activities::Groups::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.metadata_template.destroy_html', user: @user.email,
                                                                template_name: template.name)
      )

      assert_no_selector 'a', text: @template.name
    end

    test 'permanently deleted template activity' do
      template = metadata_templates(:valid_group_metadata_template)
      group = groups(:group_one)

      MetadataTemplates::DestroyService.new(
        @user, template
      ).execute

      MetadataTemplate.only_deleted.find_by(id: template.id).really_destroy!

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.metadata_template.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.metadata_template.destroy_html'
      end

      render_inline Activities::Groups::MetadataTemplateActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.metadata_template.destroy_html', user: @user.email,
                                                                template_name: template.name)
      )

      assert_no_selector 'a', text: @template.name
    end
  end
end
