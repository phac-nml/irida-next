# frozen_string_literal: true

require 'test_helper'

module Groups
  class MembersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get group members listing => members#index' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      assert_response :success

      w3c_validate 'Group Members Listing Page'
    end

    test 'should display add new member to group page' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get new_group_member_path(group)
      assert_response :success
    end

    test 'should apply default sort and support sorting group members' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      group_member_bot = members(:group_one_member_user_bot_account)
      group_member_james = members(:group_one_member_james_doe)
      group_member_joan = members(:group_one_member_joan_doe)
      group_member_ryan = members(:group_one_member_ryan_doe)
      owner_emails = [members(:group_one_member_james_doe).user.email, members(:group_one_member_john_doe).user.email]

      get group_members_path(group, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(group_member_bot.user.email, group_member_james.user.email, row_scope: '#members-table-body')

      get group_members_path(group, format: :turbo_stream, members_q: { s: 'user_email desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(group_member_ryan.user.email, members(:group_one_member_john_doe).user.email,
                                row_scope: '#members-table-body')

      get group_members_path(group, format: :turbo_stream, members_q: { s: 'access_level asc' })
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_first_rows_include(group_member_ryan.user.email, group_member_bot.user.email, row_scope: '#members-table-body')

      get group_members_path(group, format: :turbo_stream, members_q: { s: 'access_level desc' })
      assert_response :success
      assert_sort_state(2, 'descending')
      member_emails = Nokogiri::HTML(response.body).css('#members-table-body tr td:first-child').filter_map do |node|
        node.text[/[A-Za-z0-9_.+\-]+@[A-Za-z0-9\-.]+/]
      end
      assert_includes owner_emails, member_emails.first
      assert_equal group_member_ryan.user.email, member_emails.last

      get group_members_path(group, format: :turbo_stream, members_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(group_member_joan.user.email, group_member_james.user.email, row_scope: '#members-table-body')
    end

    test 'should add new member to group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      user = users(:steve_doe)

      assert_difference('Member.count') do
        post group_members_path, params: { member: { user_id: user.id,
                                                     access_level: Member::AccessLevel::OWNER }, format: :turbo_stream }
      end

      assert_response :success
    end

    test 'should delete a member from the group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      group_member = members(:group_one_member_james_doe)

      assert_difference('Member.count', -1) do
        delete group_member_path(group, group_member, format: :turbo_stream)
      end

      assert_response :ok
    end

    test 'should redirect user to groups dashboard when they leave the group' do
      sign_in users(:james_doe)

      group = groups(:group_one)
      get group_members_path(group)
      group_member = members(:group_one_member_james_doe)

      assert_difference('Member.count', -1) do
        delete group_member_path(group, group_member, format: :turbo_stream)
      end

      assert_redirected_to dashboard_groups_url
    end

    test 'shouldn\'t delete a member from the group' do
      sign_in users(:joan_doe)

      group = groups(:group_one)
      group_member = members(:group_one_member_james_doe)

      assert_no_difference('Member.count') do
        delete group_member_path(group, group_member, format: :turbo_stream)
      end

      assert_response :unprocessable_content
    end
  end
end
