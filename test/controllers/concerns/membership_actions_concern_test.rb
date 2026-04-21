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
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end

  def available_users
    @available_users = User.where.not(id: Member.where(namespace_id: @namespace.id).select(:user_id))
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
      @controller.create
      assert @namespace.nil?
      assert @member.nil?
    end
  end

  test 'calling destroy on the controller with members_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.destroy
      assert @namespace.nil?
      assert @member.nil?
    end
  end

  test 'calling index should not result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    @controller.index

    assert @namespace.nil?
    assert @member.nil?
  end

  test 'calling new should not result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    @controller.new

    assert @namespace.nil?
    assert @member.nil?
  end

  test 'calling member_namespace should result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.send(:member_namespace)
    end

    assert @namespace.nil?
    assert @member.nil?
  end

  test 'calling authorize_view_members should result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.send(:authorize_view_members)
    end

    assert @namespace.nil?
    assert @member.nil?
  end

  test 'calling authorize_modify_members should result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.send(:authorize_modify_members)
    end

    assert @namespace.nil?
    assert @member.nil?
  end
end
