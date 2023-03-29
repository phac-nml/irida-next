# frozen_string_literal: true

require 'test_helper'

class TestClassController < ApplicationController
  include MembershipActions

  def index; end

  def new; end

  def create
    redirect_to members_path
  end

  def destroy
    redirect_to members_path
  end

  private

  def access_levels
    member_user = Member.find_by(user: current_user, namespace: @namespace, type: @member_type)
    @access_levels = Member.access_levels(member_user, current_user.id == @namespace.owner_id)
  end

  def available_users
    @available_users = User.where.not(id: Member.where(type: @member_type,
                                                       namespace_id: @namespace.id).pluck(:user_id))
    # Remove current user from available users as a user cannot add themselves
    @available_users = @available_users.to_a - [current_user]
  end
end

class MembershipActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'calling create on the controller with members_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      get @controller.create
    end
  end

  test 'calling destroy on the controller with members_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      get @controller.destroy
    end
  end

  test 'calling index should not result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    get @controller.index

    assert_response :success
  end

  test 'calling new should not result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    get @controller.new

    assert_response :success
    assert_equal 2, group.group_members.count
  end

  test 'group members create' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)
    user = users(:john_doe)

    post group_members_path, params: { member: { user_id: user.id,
                                                 access_level: Member::AccessLevel::OWNER } }

    assert_redirected_to group_members_path(group)
    assert_equal 3, group.group_members.count
  end

  test 'group members destroy' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)
    group_member = members_group_members(:group_one_member_james_doe)

    delete group_member_path(group, group_member)

    assert_redirected_to group_members_path(group)
    assert_equal 1, group.group_members.count
  end
end
