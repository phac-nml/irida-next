# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class TransferInActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      @group = groups(:group_one)
    end

    test 'transfer group into group activity' do
      group2 = groups(:group_two)

      ::Groups::TransferService.new(group2, @user).execute(@group)

      activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.transfer_in_no_exisiting_namespace')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.transfer_in_no_exisiting_namespace_html'
      end

      render_inline Activities::Groups::TransferInActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.transfer_in_no_exisiting_namespace_html', user: @user.email,
                                                                         new_namespace: @group.puid,
                                                                         href: group2.puid)
      )

      assert_selector 'a',
                      text: group2.puid
    end

    test 'transfer group from an existing group namespace into group activity' do
      group2 = groups(:group_two)
      subgroup = groups(:subgroup1)

      ::Groups::TransferService.new(subgroup, @user).execute(group2)

      activities = group2.human_readable_activity(group2.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.transfer_in_html')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.transfer_in_html'
      end

      render_inline Activities::Groups::TransferInActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.transfer_in_html', user: @user.email,
                                                  old_namespace: @group.puid,
                                                  new_namespace: group2.puid,
                                                  href: subgroup.puid)
      )

      assert_selector 'a',
                      text: subgroup.puid
    end

    test 'transfer group from an existing group namespace into group then delete transferred group activity' do
      group2 = groups(:group_two)
      subgroup = groups(:subgroup1)

      ::Groups::TransferService.new(subgroup, @user).execute(group2)

      subgroup.destroy!

      activities = group2.human_readable_activity(group2.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.transfer_in_html')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.transfer_in_html'
      end

      render_inline Activities::Groups::TransferInActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.transfer_in_html', user: @user.email,
                                                  old_namespace: @group.puid,
                                                  new_namespace: group2.puid,
                                                  href: subgroup.puid)
      )

      assert_no_selector 'a',
                         text: subgroup.puid
    end
  end
end
