# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  module Projects
    class CrudActivityComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        @group = groups(:group_one)
        @project = projects(:project1)
      end

      test 'project created in group activity' do
        activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.projects.create')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.projects.create_html'
        end

        render_inline Activities::Groups::Projects::CrudActivityComponent.new(activity: activity_to_render)

        assert_text strip_tags(
          I18n.t('activity.group.projects.create_html', user: 'System',
                                                        href: @project.namespace.puid)
        )
        assert_selector 'a',
                        text: @project.namespace.puid
      end

      test 'project removed from group activity' do
        ::Projects::DestroyService.new(@project, @user).execute

        activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.projects.destroy')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.projects.destroy_html'
        end

        render_inline Activities::Groups::Projects::CrudActivityComponent.new(activity: activity_to_render)

        assert_text strip_tags(
          I18n.t('activity.group.projects.destroy_html', user: @user.email,
                                                         href: @project.namespace.puid)
        )
        assert_selector 'span',
                        text: @project.namespace.puid
      end

      test 'project created in group and then removed activity' do
        ::Projects::DestroyService.new(@project, @user).execute

        activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.projects.create')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.projects.create_html'
        end

        render_inline Activities::Groups::Projects::CrudActivityComponent.new(activity: activity_to_render)

        assert_text strip_tags(
          I18n.t('activity.group.projects.create_html', user: 'System',
                                                        href: @project.namespace.puid)
        )
        assert_selector 'span',
                        text: @project.namespace.puid
      end
    end
  end
end
