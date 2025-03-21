# frozen_string_literal: true

require 'test_helper'

class GroupsMembershipActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'group members index' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)

    assert_response :success
    assert_equal 5, group.group_members.count

    w3c_validate 'Group Members Page'
  end

  test 'group members index invalid route get' do
    sign_in users(:john_doe)

    get group_members_path(group_id: 'test-group-not-exists')
    assert_response :not_found
  end

  test 'group members new' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get new_group_member_path(group, format: :turbo_stream)

    assert_response :success
    assert_equal 5, group.group_members.count
  end

  test 'group members new invalid route get' do
    sign_in users(:john_doe)

    get new_group_member_path(group_id: 'test-group-not-exists')
    assert_response :not_found
  end

  test 'group members create' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)
    user = users(:john_doe)

    post group_members_path, params: { member: { user_id: users(:steve_doe).id,
                                                 namespace_id: group.id,
                                                 created_by_id: user.id,
                                                 access_level: Member::AccessLevel::OWNER }, format: :turbo_stream }

    assert_response :success
    assert_equal 6, group.group_members.count
  end

  test 'group members create invalid post data' do
    sign_in users(:john_doe)
    user = users(:john_doe)
    group = groups(:group_one)

    post group_members_path(group), params: { member: { user_id: user.id,
                                                        namespace_id: group.id,
                                                        created_by_id: user.id,
                                                        access_level: Member::AccessLevel::OWNER + 100_000 },
                                              format: :turbo_stream }
    assert_response :unprocessable_entity
  end

  test 'group members destroy' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)
    group_member = members(:group_one_member_james_doe)

    delete group_member_path(group, group_member, format: :turbo_stream)

    assert_response :ok
    assert_equal 4, group.group_members.count
  end

  test 'group members destroy invalid route delete' do
    sign_in users(:john_doe)

    group_member = members(:group_one_member_james_doe)
    delete group_member_path('test-group-not-exists', group_member)

    assert_response :not_found
  end

  test 'group members create invalid' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_members_path(group)
    user = users(:john_doe)

    post group_members_path, params: { member: { user_id: user.id,
                                                 namespace_id: group.id,
                                                 created_by_id: user.id,
                                                 access_level: Member::AccessLevel::OWNER + 100_000 },
                                       format: :turbo_stream }

    assert_response :unprocessable_entity
  end

  test 'group members destroy invalid' do
    sign_in users(:joan_doe)

    group = groups(:group_one)
    group_member = members(:group_one_member_james_doe)

    assert_no_changes -> { group.group_members.count } do
      delete group_member_path(group, group_member, format: :turbo_stream)
    end

    assert_response :unprocessable_entity
  end

  test 'update group member access role as owner' do
    sign_in users(:john_doe)

    group = groups(:group_five)
    group_member = members(:group_five_member_michelle_doe)

    patch group_member_path(group, group_member),
          params: { member: {
            access_level: Member::AccessLevel::ANALYST
          }, format: :turbo_stream }

    assert_equal Member.find_by(user_id: group_member.user.id,
                                namespace_id: group_member.namespace.id).access_level,
                 Member::AccessLevel::ANALYST

    assert_response :success
  end

  test 'update group member access role as maintainer' do
    sign_in users(:micha_doe)

    group = groups(:group_five)
    group_member = members(:group_five_member_michelle_doe)

    patch group_member_path(group, group_member),
          params: { member: {
            access_level: Member::AccessLevel::ANALYST
          }, format: :turbo_stream }

    assert_equal Member.find_by(user_id: group_member.user.id,
                                namespace_id: group_member.namespace.id).access_level,
                 Member::AccessLevel::ANALYST

    assert_response :success
  end

  test 'update project member access role to lower level than group' do
    sign_in users(:john_doe)

    group = groups(:subgroup_one_group_five)
    group_member = members(:subgroup_one_group_five_member_james_doe)

    assert_no_changes -> { group_member.access_level } do
      patch group_member_path(group, group_member),
            params: { member: {
              access_level: Member::AccessLevel::ANALYST
            }, format: :turbo_stream }
    end

    assert_not_equal Member.find_by(user_id: group_member.user.id,
                                    namespace_id: group_member.namespace.id).access_level,
                     Member::AccessLevel::ANALYST

    assert_response :bad_request
  end

  test 'update project member access role to non existent access level' do
    sign_in users(:john_doe)

    group = groups(:subgroup_one_group_five)
    group_member = members(:subgroup_one_group_five_member_james_doe)

    assert_no_changes -> { group_member.access_level } do
      patch group_member_path(group, group_member),
            params: { member: {
              access_level: 100_000
            }, format: :turbo_stream }
    end

    assert_not_equal Member.find_by(user_id: group_member.user.id,
                                    namespace_id: group_member.namespace.id).access_level,
                     100_000

    assert_response :bad_request
  end
end
