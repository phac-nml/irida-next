# frozen_string_literal: true

require 'test_helper'

module Groups
  class GroupLinksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)

      @namespace = groups(:group_one)
    end

    test 'should apply default sort and support sorting group links' do
      group_link5 = namespace_group_links(:namespace_group_link5)
      group_link14 = namespace_group_links(:namespace_group_link14)

      get group_group_links_path(@namespace, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(group_link5.group.name, group_link14.group.name)

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'group_name desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(group_link14.group.name, group_link5.group.name)

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'group_access_level asc' })
      assert_response :success
      assert_sort_state(4, 'ascending')
      assert_first_rows_include(group_link5.group.name, group_link14.group.name)

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(group_link5.group.name, group_link14.group.name)
    end

    test 'should share group b with group a' do
      group_six = groups(:group_six)

      post group_group_links_path(group_six,
                                  params: { namespace_group_link: {
                                    group_id: @namespace.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :ok
    end

    test 'should not share group b with group a as group b doesn\'t exist' do
      group_id = 1

      post group_group_links_path(@namespace,
                                  params: { namespace_group_link: {
                                    group_id:,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'should not share group b with group a as user doesn\'t have correct permissions' do
      sign_in users(:micha_doe)
      group_six = groups(:group_six)

      post group_group_links_path(group_six,
                                  params: { namespace_group_link: {
                                    group_id: @namespace.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  } })

      assert_response :unauthorized
    end

    test 'group b already shared with group a' do
      sign_in users(:john_doe)
      group_six = groups(:group_six)

      post group_group_links_path(group_six,
                                  params: { namespace_group_link: {
                                    group_id: @namespace.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :ok

      post group_group_links_path(group_six,
                                  params: { namespace_group_link: {
                                    group_id: @namespace.id,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'unshare group' do
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
      namespace = groups(:group_six)

      delete group_group_link_path(namespace, 1,
                                   format: :turbo_stream)

      assert_response :not_found
    end

    test 'should update namespace group share' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                    namespace_group_link: {
                                      group_access_level: Member::AccessLevel::GUEST
                                    }, format: :turbo_stream
                                  })

      assert_response :ok
    end

    test 'should not update namespace group share due to invalid params' do
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                    namespace_group_link: {
                                      group_access_level: -1
                                    }, format: :turbo_stream
                                  })

      assert_response :unprocessable_content
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

    test 'access edit group link' do
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      get edit_group_group_link_path(@namespace, namespace_group_link, format: :turbo_stream)

      assert_response :success
    end

    test 'cannot access edit group link' do
      sign_in users(:ryan_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      get edit_group_group_link_path(@namespace, namespace_group_link, format: :turbo_stream)

      assert_response :unauthorized
    end
  end
end
