# frozen_string_literal: true

require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  def setup
    @member = members(:member_one)
  end

  test 'valid group member' do
    assert @member.valid?
  end

  test 'invalid namespace member' do
    @member2 = members(:member_two)
    assert_not @member2.valid?
  end

  test 'member belongs to a user' do
    assert_not_nil @member.user
  end

  test 'member belongs to a group namespace' do
    assert_equal 'Group', @member.namespace.type
  end

  test 'group member should have a role' do
    assert_not_nil @member.role
  end

  test 'group member should not have metadata role' do
    assert_nil @member.metadata_role
  end
end
