# frozen_string_literal: true

require 'test_helper'

class TestClassController < ApplicationController
  include ShareActions

  def share
    redirect_to namespace_path
  end

  def unshare
    redirect_to namespace_path
  end
end

class ShareActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'calling share on the controller with namespace_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      post @controller.share
    end
  end

  test 'calling unshare on the controller with namespace_path not implemented' do
    sign_in users(:john_doe)

    @controller = TestClassController.new
    assert_raises(NotImplementedError) do
      post @controller.unshare
    end
  end
end
