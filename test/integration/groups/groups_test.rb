# frozen_string_literal: true

require 'test_helper'

module Groups
  class GroupsTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      Flipper.enable(:global_groups)
    end

    def teardown
      Flipper.disable(:global_groups)
    end
    test 'should get new group page' do
      sign_in @user
      get new_group_path
      assert_response :success

      assert_select 'h1', text: I18n.t(:'groups.create.title')
      assert_select 'div', text: I18n.t(:'groups.new.visibility.title')
      assert_select 'label', text: I18n.t(:'groups.new.visibility.private.label')
      assert_select 'span', text: I18n.t(:'groups.new.visibility.private.description')
      assert_select 'label', text: I18n.t(:'groups.new.visibility.public.label')
      assert_select 'span', text: I18n.t(:'groups.new.visibility.public.description')
    end

    test 'should create a group' do
      sign_in @user
      created_group = nil

      params = { group: { name: 'New Group', path: 'new-group', description: 'This is a new group', public: true } }

      assert_difference('Group.count', 1) do
        post groups_path, params: params
        created_group = Group.last
      end

      follow_redirect!
      assert_response :success

      assert_select 'h1', text: 'New Group'

      get edit_group_path(created_group)
      assert_response :success

      assert_select 'h1', text: I18n.t(:'groups.edit.details.title')

      assert_select 'h2', text: I18n.t(:'groups.edit.advanced.change_visibility.title')
      assert_select 'p', text: I18n.t(:'groups.edit.advanced.change_visibility.description.public')
      assert_select 'button[type=submit][disabled]'

      created_group = nil
      params = { group: { name: 'New Group 2', path: 'new-group-2', description: 'This is another new group' } }

      assert_difference('Group.count', 1) do
        post groups_path, params: params
        created_group = Group.last
      end

      follow_redirect!
      assert_response :success

      assert_select 'h1', text: 'New Group 2'

      get edit_group_path(created_group)

      assert_select 'h2', text: I18n.t(:'groups.edit.advanced.change_visibility.title')
      assert_select 'p', text: I18n.t(:'groups.edit.advanced.change_visibility.description.private')
      assert_select 'button[type=submit][disabled]'
    end

    test 'should not display visibility options when global_groups is disabled' do
      Flipper.disable(:global_groups)
      sign_in @user
      get new_group_path
      assert_response :success

      assert_select 'div', text: I18n.t(:'groups.new.visibility.title'), count: 0
      assert_select 'label', text: I18n.t(:'groups.new.visibility.private.label'), count: 0
      assert_select 'span', text: I18n.t(:'groups.new.visibility.private.description'), count: 0
      assert_select 'label', text: I18n.t(:'groups.new.visibility.public.label'), count: 0
      assert_select 'span', text: I18n.t(:'groups.new.visibility.public.description'), count: 0
    end

    test 'can create a group with global_groups is disabled' do
      Flipper.disable(:global_groups)
      sign_in @user

      params = { group: { name: 'New Group 3', path: 'new-group-3', description: 'This is yet another new group' } }
      created_group = nil

      assert_difference('Group.count', 1) do
        post groups_path, params: params
        created_group = Group.last
      end

      follow_redirect!
      assert_response :success

      assert_select 'h1', text: 'New Group 3'

      get edit_group_path(created_group)
      assert_response :success

      assert_select 'h2', text: I18n.t(:'groups.edit.advanced.change_visibility.title'), count: 0
    end
  end
end
