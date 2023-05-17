# frozen_string_literal: true

require 'test_helper'

module Groups
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_one)
    end

    test 'update group with valid params' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      assert_changes -> { [@group.name, @group.path] }, to: %w[new-group1-name new-group1-path] do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end
    end

    test 'update group with invalid params' do
      invalid_params = { name: 'g1', path: 'g1' }

      assert_no_changes -> { @group } do
        Groups::UpdateService.new(@group, @user, invalid_params).execute
      end
    end

    test 'update group with incorrect permissions' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::UpdateService.new(@group, user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to update group' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      assert_authorized_to(:manage?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end
    end
  end
end
