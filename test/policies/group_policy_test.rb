# frozen_string_literal: true

require 'test_helper'

class GroupPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @policy = GroupPolicy.new(@group, user: @user)
  end

  test '#view?' do
    assert @policy.view?
  end

  test '#manage?' do
    assert @policy.manage?
  end

  test '#create?' do
    assert @policy.create?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end

  test 'aliases' do
    assert_equal :create?, @policy.resolve_rule(:create?)
    assert_equal :create?, @policy.resolve_rule(:new?)

    assert_equal :manage?, @policy.resolve_rule(:edit?)
    assert_equal :manage?, @policy.resolve_rule(:update?)

    assert_equal :view?, @policy.resolve_rule(:show?)
    assert_equal :view?, @policy.resolve_rule(:index?)

    assert_equal :destroy?, @policy.resolve_rule(:destroy?)
  end

  test 'scope' do
    scoped_groups = @policy.apply_scope(Group, type: :relation)

    # John Doe has access to 14 groups
    assert_equal scoped_groups.count, 17

    user = users(:david_doe)
    policy = GroupPolicy.new(user:)
    scoped_groups = policy.apply_scope(Group, type: :relation)
    # David Doe has access to 1 group
    assert_equal scoped_groups.count, 1
  end
end
