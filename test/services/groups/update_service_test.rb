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
      assert_equal :update?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.update?', name: @group.name), exception.result.message
    end

    test 'valid authorization to update group' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      assert_authorized_to(:update?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end
    end

    test 'group update changes logged using logidze' do
      @group.create_logidze_snapshot!

      assert_equal 1, @group.log_data.version
      assert_equal 1, @group.log_data.size

      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      assert_changes -> { [@group.name, @group.path] }, to: %w[new-group1-name new-group1-path] do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end

      @group.create_logidze_snapshot!

      assert_equal 2, @group.log_data.version
      assert_equal 2, @group.log_data.size

      assert_equal 'Group 1', @group.at(version: 1).name
      assert_equal 'group-1', @group.at(version: 1).path

      assert_equal 'new-group1-name', @group.at(version: 2).name
      assert_equal 'new-group1-path', @group.at(version: 2).path

      # Description was not updated so it should not be in the changes log
      assert_nil @group.diff_from(version: 1)['changes']['description']
    end

    test 'group update changes logged using logidze switch version' do
      @group.create_logidze_snapshot!

      assert_equal 1, @group.log_data.version
      assert_equal 1, @group.log_data.size

      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      assert_changes -> { [@group.name, @group.path] }, to: %w[new-group1-name new-group1-path] do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end

      @group.create_logidze_snapshot!

      assert_equal 2, @group.log_data.version
      assert_equal 2, @group.log_data.size

      assert_equal 'Group 1', @group.at(version: 1).name
      assert_equal 'group-1', @group.at(version: 1).path

      assert_equal 'new-group1-name', @group.at(version: 2).name
      assert_equal 'new-group1-path', @group.at(version: 2).path

      @group.switch_to!(1)

      assert_equal 1, @group.log_data.version
      assert_equal 2, @group.log_data.size

      assert_equal 'Group 1', @group.name
      assert_equal 'group-1', @group.path
    end
  end
end
