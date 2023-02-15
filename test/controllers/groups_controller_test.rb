# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should show the group' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_path(group.full_path)
    assert_response :success
  end

  test 'should show the sub group' do
    sign_in users(:john_doe)

    subgroup = groups(:subgroup1)
    get group_path(subgroup.full_path)
    assert_response :success
  end

  test 'should not show a sub group that doesn\'t exist' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    assert_raises(ActionController::RoutingError) do
      get group_path("#{group.full_path}/fakesubgroup")
    end
  end
end
