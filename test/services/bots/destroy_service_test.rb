# frozen_string_literal: true

require 'test_helper'

module Bots
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @bot_account = users(:user_bot_account)
    end

    test 'destroy bot account' do
      assert_difference -> { User.count } => -1, -> { PersonalAccessToken.count } => -1, -> { Member.count } => -1 do
        Bots::DestroyService.new(@bot_account, @project.namespace, @user).execute
      end
    end

    test 'valid authorization to destroy bot account' do
      assert_authorized_to(:destroy_bot_accounts?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Bots::DestroyService.new(@bot_account, @project.namespace, @user).execute
      end
    end

    test 'invalid authorization to destroy bot account' do
      user = users(:micha_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::DestroyService.new(@bot_account, @project.namespace, user).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :destroy_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.destroy_bot_accounts?', name: @project.name),
                   exception.result.message
    end
  end
end
