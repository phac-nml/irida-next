# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @policy = UserPolicy.new(@user, user: @user)
  end

  test '#update?' do
    assert @policy.apply(:update?)
  end

  test '#edit?' do
    assert @policy.apply(:edit?)
  end

  test '#destroy?' do
    assert @policy.apply(:destroy?)
  end

  test '#revoke?' do
    assert @policy.apply(:revoke?)
  end

  test '#read?' do
    assert @policy.apply(:read?)
  end

  test '#index?' do
    assert @policy.apply(:index?)
  end

  test '#new?' do
    assert @policy.apply(:new?)
  end

  test '#create?' do
    assert @policy.apply(:create?)
  end
end
