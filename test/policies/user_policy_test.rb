# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @policy = UserPolicy.new(@user, user: @user)
  end

  test '#manage?' do
    assert @policy.manage?
  end

  test 'aliases' do
    assert_equal :manage?, @policy.resolve_rule(:show?)
    assert_equal :manage?, @policy.resolve_rule(:create?)
    assert_equal :manage?, @policy.resolve_rule(:update?)
    assert_equal :manage?, @policy.resolve_rule(:edit?)
    assert_equal :manage?, @policy.resolve_rule(:index?)
    assert_equal :manage?, @policy.resolve_rule(:destroy?)
    assert_equal :manage?, @policy.resolve_rule(:revoke?)
  end
end
