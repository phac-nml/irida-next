# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @policy = UserPolicy.new(@user, user: @user)
  end

  test '#profile_owner?' do
    assert @policy.profile_owner?
  end

  test 'aliases' do
    assert_equal :profile_owner?, @policy.resolve_rule(:show?)
    assert_equal :profile_owner?, @policy.resolve_rule(:create?)
    assert_equal :profile_owner?, @policy.resolve_rule(:update?)
    assert_equal :profile_owner?, @policy.resolve_rule(:edit?)
    assert_equal :profile_owner?, @policy.resolve_rule(:index?)
    assert_equal :profile_owner?, @policy.resolve_rule(:destroy?)
    assert_equal :profile_owner?, @policy.resolve_rule(:revoke?)
  end
end
