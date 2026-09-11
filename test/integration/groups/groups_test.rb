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

      assert_select 'h1', text: I18n.t(:'groups.edit.details.title')

      assert_select 'h2', text: I18n.t(:'groups.edit.advanced.change_visibility.title')
      assert_select 'p', text: I18n.t(:'groups.edit.advanced.change_visibility.description.public')

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
    end
  end
end
