# frozen_string_literal: true

require 'test_helper'

module Groups
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_two)
    end

    test 'delete group with correct permissions' do
      assert_difference -> { Group.count } => -1 do
        Groups::DestroyService.new(@group, @user).execute
      end
      assert @group.errors.empty?
    end

    test 'delete group with incorrect permissions' do
      user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::DestroyService.new(@group, user).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to destroy group' do
      assert_authorized_to(:destroy?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Groups::DestroyService.new(@group, @user).execute
      end
    end
  end
end
