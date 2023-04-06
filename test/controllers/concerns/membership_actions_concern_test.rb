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
  end
end
