# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  module Projects
    class TransferActivityComponentTest < ViewComponentTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        @group = groups(:group_one)
        @group2 = groups(:group_two)
        @project = projects(:project1)
      end

      test 'project transfer into group activity' do
        activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.projects.transfer_in')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.projects.transfer_in_html'
        end

        render_inline Activities::Groups::Projects::TransferActivityComponent.new(activity: activity_to_render)

        assert_text strip_tags(
          I18n.t('activity.group.projects.transfer_in_html', user: 'System',
                                                             old_namespace: @group2.puid,
                                                             new_namespace: @group.puid,
                                                             href: @project.namespace.puid)
        )
        assert_selector 'a',
                        text: @project.namespace.puid
      end

      test 'project transfer into group and project deleted activity' do
        ::Projects::DestroyService.new(@project, @user).execute

        activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

        assert_equal(1, activities.count do |activity|
          activity[:key].include?('group.projects.transfer_in')
        end)

        activity_to_render = activities.find do |a|
          a[:key] == 'activity.group.projects.transfer_in_html'
        end

        render_inline Activities::Groups::Projects::TransferActivityComponent.new(activity: activity_to_render)

        assert_text strip_tags(
          I18n.t('activity.group.projects.transfer_in_html', user: 'System',
                                                             old_namespace: @group2.puid,
                                                             new_namespace: @group.puid,
                                                             href: @project.namespace.puid)
        )
        assert_selector 'a[disabled="disabled"]',
                        text: @project.namespace.puid
      end
    end
  end
end
