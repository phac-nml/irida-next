# frozen_string_literal: true

require 'test_helper'

module Groups
  class ShareServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'share group a with group b' do
      group = groups(:group_one)
      group_to_share_with_id = groups(:group_six).id

      assert_difference -> { GroupGroupLink.count } => 1 do
        Groups::ShareService.new(@user, group, group_to_share_with_id, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'share group a with group b with incorrect permissions' do
      user = users(:ryan_doe)
      group = groups(:group_one)
      group_to_share_with_id = groups(:group_six).id

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::ShareService.new(user, group, group_to_share_with_id, Member::AccessLevel::ANALYST).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :share_group_with_other_groups?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.share_group_with_other_groups?', name: group.name),
                   exception.result.message
    end

    test 'share group a with group n where n is a group with an invalid id' do
      group = groups(:group_one)
      group_to_share_with_id = 1

      assert_no_difference ['GroupGroupLink.count'] do
        Groups::ShareService.new(@user, group, group_to_share_with_id, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'valid authorization to share group with other groups' do
      group = groups(:group_one)
      group_to_share_with_id = groups(:group_six).id

      assert_authorized_to(:share_group_with_other_groups?, group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Groups::ShareService.new(@user, group, group_to_share_with_id, Member::AccessLevel::ANALYST).execute
      end
    end

    test 'group a shared with group b is logged using logidze' do
      group = groups(:group_one)
      group_to_share_with_id = groups(:group_six).id

      group_group_link = Groups::ShareService.new(@user, group, group_to_share_with_id,
                                                  Member::AccessLevel::ANALYST).execute
      group_group_link.create_logidze_snapshot!

      assert_equal 1, group_group_link.log_data.version
      assert_equal 1, group_group_link.log_data.size

      assert_equal group.id, group_group_link.at(version: 1).shared_group_id
      assert_equal group_to_share_with_id, group_group_link.at(version: 1).shared_with_group_id
      assert_equal Member::AccessLevel::ANALYST, group_group_link.at(version: 1).group_access_level
    end
  end
end
