# frozen_string_literal: true

require 'test_helper'

module Groups
  class SharedNamespacesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
    end

    test 'should redirect to groups index when html format requested' do
      get group_shared_namespaces_url(@group)
      assert_redirected_to group_url(@group)
    end

    test 'should get fragment of namesapce tree' do
      get group_shared_namespaces_url(@group), params: { parent_id: @group.id, format: :turbo_stream }
      assert_response :ok
    end
  end
end
