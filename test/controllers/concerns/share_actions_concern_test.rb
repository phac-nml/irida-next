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
end

class ShareActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'calling share on the controller with group_links_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      post @controller.create
    end
  end

  test 'calling unshare on the controller with group_links_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      post @controller.destroy
    end
  end
end
