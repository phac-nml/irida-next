# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class SubgroupActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      @group = groups(:group_one)
      @subgroup = groups(:subgroup1)
    end

    test 'create subgroup activity' do
      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.subgroups.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.subgroups.create_html'
      end

      render_inline Activities::Groups::SubgroupActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.subgroups.create_html', user: 'System',
                                                       href: @subgroup.puid)
      )
      assert_selector 'a',
                      text: @subgroup.puid
    end

    test 'remove subgroup activity' do
      ::Groups::DestroyService.new(@subgroup, @user).execute

      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.subgroups.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.subgroups.destroy_html'
      end

      render_inline Activities::Groups::SubgroupActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.subgroups.destroy_html', user: @user.email,
                                                        removed_group_puid: @subgroup.puid)
      )
      assert_no_selector 'a',
                         text: @subgroup.puid
    end

    test 'create subgroup and then soft delete activity' do
      ::Groups::DestroyService.new(@subgroup, @user).execute

      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.subgroups.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.subgroups.create_html'
      end

      render_inline Activities::Groups::SubgroupActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.subgroups.create_html', user: 'System',
                                                       href: @subgroup.puid)
      )

      assert_no_selector 'a',
                         text: @subgroup.puid
    end

    test 'create subgroup and then transfer to another parent group activity' do
      group2 = groups(:group_two)
      ::Groups::TransferService.new(@subgroup, @user).execute(group2)

      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.subgroups.create')
      end)

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.transfer_out')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.subgroups.create_html'
      end

      render_inline Activities::Groups::SubgroupActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.subgroups.create_html', user: 'System',
                                                       href: @subgroup.puid)
      )

      assert_no_selector 'a',
                         text: @subgroup.puid
    end
  end
end
