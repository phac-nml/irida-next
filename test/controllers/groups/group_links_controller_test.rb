# frozen_string_literal: true

require 'test_helper'

module Groups
  class GroupLinksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should share group b with group a' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_group_links_path(namespace,
                                  params: { namespace_group_link: {
                                    group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :ok
    end

    test 'should not share group b with group a as group b doesn\'t exist' do
      sign_in users(:john_doe)
      group_id = 1
      namespace = groups(:group_one)

      post group_group_links_path(namespace,
                                  params: { namespace_group_link: {
                                    group_id:,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :unprocessable_entity
    end

    test 'should not share group b with group a as user doesn\'t have correct permissions' do
      sign_in users(:micha_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_group_links_path(namespace,
                                  params: { namespace_group_link: {
                                    group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  } })

      assert_response :unauthorized
    end

    test 'group b already shared with group a' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      namespace = groups(:group_six)

      post group_group_links_path(namespace,
                                  params: { namespace_group_link: {
                                    group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :ok

      post group_group_links_path(namespace,
                                  params: { namespace_group_link: {
                                    group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :unprocessable_entity
    end

    test 'unshare group' do
      sign_in users(:john_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link2)
      namespace = namespace_group_link.namespace

      delete group_group_link_path(namespace, namespace_group_link.id,
                                   format: :turbo_stream)
      assert_response :ok
    end

    test 'should not unshare group b with group a as user doesn\'t have correct permissions' do
      sign_in users(:david_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link2)
      namespace = namespace_group_link.namespace

      delete group_group_link_path(namespace, namespace_group_link.id)

      assert_response :unauthorized
    end

    test 'unshare group when link doesn\'t exist with another group' do
      sign_in users(:john_doe)
      namespace = groups(:group_six)

      delete group_group_link_path(namespace, 1,
                                   format: :turbo_stream)

      assert_response :not_found
    end

    test 'should update namespace group share' do
      sign_in users(:john_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link2)

      patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                    namespace_group_link: {
                                      group_access_level: Member::AccessLevel::GUEST
                                    }, format: :turbo_stream
                                  })

      assert_response :ok
    end

    test 'should not update namespace group share due to invalid params' do
      sign_in users(:john_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link2)

      patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                    namespace_group_link: {
                                      group_access_level: -1
                                    }, format: :turbo_stream
                                  })

      assert_response :unprocessable_entity
    end

    test 'should not update namespace group share due to incorrect permissions' do
      sign_in users(:david_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link2)

      patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                    namespace_group_link: {
                                      group_access_level: Member::AccessLevel::GUEST
                                    }
                                  })

      assert_response :unauthorized
    end
  end
end
