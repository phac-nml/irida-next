# frozen_string_literal: true

require 'test_helper'

class NamespaceBotTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @user_project_bot = users(:user_bot_account21)
    @project = projects(:project1)
    @namespace = @project.namespace
  end

  test 'valid namespace bot' do
    namespace_bot = NamespaceBot.new(user: @user_project_bot, namespace: @namespace)
    assert namespace_bot.save
    assert namespace_bot.valid?
  end

  test 'human user cannot be set as a bot for a namespace' do
    namespace_bot = NamespaceBot.new(user: @user, namespace: @namespace)
    assert_not namespace_bot.save
  end

  test 'destroying a namespace bot should destroy the underlying bot user' do
    namespace_bot = namespace_bots(:project1_bot0)

    assert_difference(
      -> { NamespaceBot.count } => -1,
      -> { User.count } => 0,
      -> { PersonalAccessToken.count } => 0,
      -> { Member.count } => -1
    ) do
      namespace_bot.destroy
    end
  end

  test 'validate_bot_user_type' do
    valid_namespace_bot = namespace_bots(:project1_bot0)
    assert_not valid_namespace_bot.errors.full_messages.any?

    valid_namespace_bot.validate_bot_user_type
    assert_not valid_namespace_bot.errors.full_messages.any?

    invalid_user_bot = namespace_bots(:invalid_user_bot)
    assert_not invalid_user_bot.errors.full_messages.any?

    invalid_user_bot.validate_bot_user_type
    assert invalid_user_bot.errors.full_messages.any?
  end

  test 'remove_membership_from_namespace' do
    namespace_bot = namespace_bots(:project1_bot0)
    membership = namespace_bot.user.members.find_by(namespace: namespace_bot.namespace)

    assert_not_nil membership
    assert namespace_bot.membership
    assert_equal membership, namespace_bot.membership

    namespace_bot.remove_membership_from_namespace
    assert_nil namespace_bot.reload.membership
  end
end
