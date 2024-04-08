# frozen_string_literal: true

require 'test_helper'

class NamespaceBotTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @user_project_bot = users(:user_bot_account0)
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
    namespace_bot = NamespaceBot.new(user: @user_project_bot, namespace: @namespace)
    assert namespace_bot.save

    assert_difference(
      -> { User.count } => -1
    ) do
      namespace_bot.destroy
    end
  end
end
