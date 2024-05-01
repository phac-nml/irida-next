# frozen_string_literal: true

require 'test_helper'

class HasUserTypeTest < ActionDispatch::IntegrationTest
  def setup
    @project1_automation_bot = users(:project1_automation_bot)
    @user_group_bot_account = users(:user_group_bot_account0)
    @user = users(:john_doe)
  end

  test 'bot?' do
    assert @project1_automation_bot.bot?
    assert @user_group_bot_account.bot?
    assert_not @user.bot?
  end

  test 'automation_bot?' do
    assert @project1_automation_bot.automation_bot?
    assert_not @user_group_bot_account.automation_bot?
  end
end
