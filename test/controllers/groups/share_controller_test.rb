# frozen_string_literal: true

require 'test_helper'

module Groups
  class ShareControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should share group b with group a' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_share_path(namespace,
                            params: { shared_group_id: group.id,
                                      group_access_level: Member::AccessLevel::ANALYST })

      assert_redirected_to group_path(namespace)
    end

    test 'should not share group b with group a as group b doesn\'t exist' do
      sign_in users(:john_doe)
      group_id = 1
      namespace = groups(:group_one)

      post group_share_path(namespace,
                            params: { shared_group_id: group_id,
                                      group_access_level: Member::AccessLevel::ANALYST })

      assert_response :unprocessable_entity
    end

    test 'shouldn\'t share group b with group a as user doesn\'t have correct permissions' do
      sign_in users(:micha_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_share_path(namespace,
                            params: { shared_group_id: group.id,
                                      group_access_level: Member::AccessLevel::ANALYST })

      assert_response :unauthorized
    end

    test 'group b already shared with group a' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_share_path(namespace,
                            params: { shared_group_id: group.id,
                                      group_access_level: Member::AccessLevel::ANALYST })

      assert_redirected_to group_path(namespace)

      post group_share_path(namespace,
                            params: { shared_group_id: group.id,
                                      group_access_level: Member::AccessLevel::ANALYST })

      assert_response :conflict
    end
  end
end
