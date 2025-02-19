# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class TransferOutActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
      @group = groups(:group_one)
      @subgroup = groups(:subgroup1)
    end

    test 'transfer subgroup to another group activity' do
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

      transfer_activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.transfer_out_html'
      end

      render_inline Activities::Groups::TransferOutActivityComponent.new(activity: transfer_activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.transfer_out_html', user: @user.email,
                                                   old_namespace: @group.puid,
                                                   new_namespace: group2.puid,
                                                   transferred_group_puid: @subgroup.puid)
      )

      assert_no_selector 'a',
                         text: @subgroup.puid

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
