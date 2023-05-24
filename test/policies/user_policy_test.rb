# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @policy = UserPolicy.new(@user, user: @user)
  end

  test '#update?' do
    assert @policy.update?
  end

  test '#edit?' do
    assert @policy.edit?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end

  test '#revoke?' do
    assert @policy.revoke?
  end

  test '#read?' do
    assert @policy.read?
  end

  test '#index?' do
    assert @policy.index?
  end

  test '#new?' do
    assert @policy.new?
  end

  test '#create?' do
    assert @policy.create?
  end
end
