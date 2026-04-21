# frozen_string_literal: true

require 'test_helper'

class TestClassController < ApplicationController
  include ShareActions

  def create
    redirect_to group_links_path
  end

  def destroy
    redirect_to group_links_path
  end

  def update
    redirect_to group_links_path
  end

  def index; end

  private

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end
end

class ShareActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'calling create on the controller with group_links_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.create
    end
  end

  test 'calling destroy on the controller with group_links_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.destroy
    end
  end

  test 'calling update on the controller with group_links_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.update
    end
  end

  test 'calling index should not result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    @controller.index

    assert @namespace.nil?
    assert @namespace_group_link.nil?
  end

  test 'calling group_link_namespace should result in an error' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      @controller.send(:group_link_namespace)
    end

    assert @namespace.nil?
    assert @namespace_group_link.nil?
    assert @member.nil?
  end
end
