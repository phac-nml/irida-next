# frozen_string_literal: true

require 'test_helper'

class GroupPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @policy = GroupPolicy.new(@group, user: @user)
  end

  test '#allowed_to_view_group?' do
    assert @policy.allowed_to_view_group?
  end

  test '#allowed_to_modify_group?' do
    assert @policy.allowed_to_modify_group?
  end

  test '#allowed_to_destroy?' do
    assert @policy.allowed_to_destroy?
  end

  test 'aliases' do
    assert_equal :allowed_to_modify_group?, @policy.resolve_rule(:create?)
    assert_equal :allowed_to_modify_group?, @policy.resolve_rule(:edit?)
    assert_equal :allowed_to_modify_group?, @policy.resolve_rule(:update?)
    assert_equal :allowed_to_modify_group?, @policy.resolve_rule(:new?)

    assert_equal :allowed_to_view_group?, @policy.resolve_rule(:show?)
    assert_equal :allowed_to_view_group?, @policy.resolve_rule(:index?)

    assert_equal :allowed_to_destroy?, @policy.resolve_rule(:destroy?)
  end
end
