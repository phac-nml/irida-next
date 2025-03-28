# frozen_string_literal: true

require 'view_component_test_case'

module GroupLinks
  class NamespaceGroupLinkActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      @project = projects(:project1)
      @group = groups(:group_one)
      @namespace_group_link = namespace_group_links(:namespace_group_link18)
      @group_namespace_group_link = namespace_group_links(:namespace_group_link5)
    end

    test 'project create namespace group link activity' do
      activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.namespace_group_link.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.namespace_group_link.create_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.namespace_group_link.create_html',
          user: 'System',
          href: @namespace_group_link.group.puid
        )
      )
      assert_selector 'a',
                      text: @namespace_group_link.group.puid
    end

    test 'project update namespace group link activity' do
      params = { group_access_level: Member::AccessLevel::GUEST }
      ::GroupLinks::GroupLinkUpdateService.new(@user, @namespace_group_link, params).execute
      activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.namespace_group_link.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.namespace_group_link.update_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.namespace_group_link.update_html',
          user: @user.email,
          href: @namespace_group_link.group.puid
        )
      )
      assert_selector 'a',
                      text: @namespace_group_link.group.puid
    end

    test 'project destroy namespace group link activity' do
      ::GroupLinks::GroupUnlinkService.new(@user, @namespace_group_link).execute
      activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.namespace_group_link.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.namespace_group_link.destroy_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.namespace_group_link.destroy_html',
          user: @user.email,
          href: @namespace_group_link.group.puid
        )
      )
      assert_selector 'span',
                      text: @namespace_group_link.group.puid
    end

    test 'project create namespace group link and permanently destroy activity' do
      ::GroupLinks::GroupUnlinkService.new(@user, @namespace_group_link).execute
      NamespaceGroupLink.only_deleted.find_by(id: @namespace_group_link.id).destroy!
      activities = @project.namespace.human_readable_activity(@project.namespace.retrieve_project_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('project_namespace.namespace_group_link.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.namespaces_project_namespace.namespace_group_link.create_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.namespaces_project_namespace.namespace_group_link.create_html',
          user: 'System',
          href: @namespace_group_link.group.puid
        )
      )
      assert_selector 'span',
                      text: @namespace_group_link.group.puid
    end

    test 'group create namespace group link activity' do
      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.create_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.create_html',
          user: 'System',
          href: @group_namespace_group_link.group.puid
        )
      )
      assert_selector 'a',
                      text: @group_namespace_group_link.group.puid
    end

    test 'group update namespace group link activity' do
      params = { group_access_level: Member::AccessLevel::GUEST }
      ::GroupLinks::GroupLinkUpdateService.new(@user, @group_namespace_group_link, params).execute
      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.update')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.update_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.update_html',
          user: @user.email,
          href: @group_namespace_group_link.group.puid
        )
      )
      assert_selector 'a',
                      text: @group_namespace_group_link.group.puid
    end

    test 'group destroy namespace group link activity' do
      ::GroupLinks::GroupUnlinkService.new(@user, @group_namespace_group_link).execute
      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.destroy_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.destroy_html',
          user: @user.email,
          href: @group_namespace_group_link.group.puid
        )
      )
      assert_selector 'span',
                      text: @group_namespace_group_link.group.puid
    end

    test 'group create namespace group link and destroy permanently activity' do
      ::GroupLinks::GroupUnlinkService.new(@user, @group_namespace_group_link).execute
      NamespaceGroupLink.only_deleted.find_by(id: @group_namespace_group_link.id).destroy!
      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.create_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.create_html',
          user: 'System',
          href: @group_namespace_group_link.group.puid
        )
      )
      assert_selector 'span',
                      text: @group_namespace_group_link.group.puid

      group = groups(:david_doe_group_four)
      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.created')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.created_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.created_html',
          user: 'System',
          href: @group_namespace_group_link.namespace.puid,
          namespace_type: 'group'
        )
      )
      assert_selector 'span',
                      text: @group_namespace_group_link.namespace.puid
    end

    test 'namespace group link group shared activity' do
      group = groups(:david_doe_group_four)
      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.created')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.created_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.created_html',
          user: 'System',
          href: @group_namespace_group_link.namespace.puid,
          namespace_type: 'group'
        )
      )
      assert_selector 'a',
                      text: @group_namespace_group_link.namespace.puid
    end

    test 'namespace group link project shared activity' do
      group = groups(:group_charlie)
      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.namespace_group_link.created')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.namespace_group_link.created_html'
      end

      render_inline Activities::NamespaceGroupLinkActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.namespace_group_link.created_html',
          user: 'System',
          href: @namespace_group_link.namespace.puid,
          namespace_type: 'project'
        )
      )
      assert_selector 'a',
                      text: @namespace_group_link.namespace.puid
    end
  end
end
