# frozen_string_literal: true

require 'test_helper'

module Groups
  class SubgroupsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
    end
    test 'should get fragment of namesapce tree' do
      get group_subgroups_url(@group), params: { parent_id: @group.id, format: :turbo_stream }
      assert_response :ok
    end
  end
end
