# frozen_string_literal: true

require 'test_helper'

module Bots
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @group = groups(:group_one)
      @project_bot = namespace_bots(:project1_bot0)
      @group_bot = namespace_bots(:group1_bot0)
    end

    test 'destroy project bot account' do
      assert_difference -> { NamespaceBot.count } => -1,
                        -> { User.count } => 0,
                        -> { PersonalAccessToken.count } => 0,
                        -> { Member.count } => -1 do
        Bots::DestroyService.new(@project_bot, @user).execute
      end
    end

    test 'valid authorization to destroy project bot account' do
      assert_authorized_to(:destroy_bot_accounts?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Bots::DestroyService.new(@project_bot, @user).execute
      end
    end

    test 'invalid authorization to destroy project bot account' do
      user = users(:micha_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::DestroyService.new(@project_bot, user).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :destroy_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.destroy_bot_accounts?',
                          name: @project.name),
                   exception.result.message
    end

    test 'destroy group bot account' do
      assert_difference -> { NamespaceBot.count } => -1,
                        -> { User.count } => 0,
                        -> { PersonalAccessToken.count } => 0,
                        -> { Member.count } => -1 do
        Bots::DestroyService.new(@group_bot, @user).execute
      end
    end

    test 'valid authorization to destroy group bot account' do
      assert_authorized_to(:destroy_bot_accounts?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Bots::DestroyService.new(@group_bot, @user).execute
      end
    end

    test 'invalid authorization to destroy group bot account' do
      user = users(:micha_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::DestroyService.new(@group_bot, user).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :destroy_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.destroy_bot_accounts?',
                          name: @group.name),
                   exception.result.message
    end
  end
end
