# frozen_string_literal: true

require 'test_helper'

class GroupShareActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'group to group links index' do
    sign_in users(:john_doe)

    group = groups(:subgroup1)
    get group_group_links_path(group, format: :turbo_stream)

    assert_response :success
    assert_equal 4, group.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'group to group link' do
    sign_in users(:john_doe)
    namespace = groups(:group_one)
    group = groups(:group_six)

    post group_group_links_path(namespace,
                                params: { namespace_group_link: {
                                  group_id: group.id,
                                  group_access_level: Member::AccessLevel::ANALYST
                                }, format: :turbo_stream })

    assert_response :success

    assert_equal 3, namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'group to self group link error' do
    sign_in users(:john_doe)
    namespace = groups(:group_one)

    assert_equal 2, namespace.shared_with_group_links.of_ancestors_and_self.count

    post group_group_links_path(namespace,
                                params: { namespace_group_link: {
                                  group_id: namespace.id,
                                  group_access_level: Member::AccessLevel::ANALYST
                                }, format: :turbo_stream })

    assert_response :unprocessable_entity

    # failed, so did not increase
    assert_equal 2, namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'group to group link destroy' do
    sign_in users(:john_doe)
    namespace_group_link = namespace_group_links(:namespace_group_link2)
    namespace = namespace_group_link.namespace

    assert_equal 4, namespace.shared_with_group_links.of_ancestors_and_self.count

    delete group_group_link_path(namespace, namespace_group_link.id,
                                 format: :turbo_stream)

    assert_response :success

    assert_equal 3, namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'group to group link update' do
    sign_in users(:john_doe)

    namespace_group_link = namespace_group_links(:namespace_group_link2)

    assert_equal namespace_group_link.group_access_level, Member::AccessLevel::ANALYST

    patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                  namespace_group_link: {
                                    group_access_level: Member::AccessLevel::GUEST
                                  }, format: :turbo_stream
                                })

    assert_response :success

    assert_equal Member::AccessLevel::GUEST, namespace_group_link.reload.group_access_level
  end
end
