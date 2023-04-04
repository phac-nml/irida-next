# frozen_string_literal: true

require 'test_helper'

module Members
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
      @project_namespace = @project.namespace
      @group = groups(:group_one)
    end

    test 'create group member with valid params' do
      user = users(:steve_doe)
      valid_params = { user:,
                       access_level: Member::AccessLevel::OWNER }

      assert_difference -> { Members::GroupMember.count } => 1 do
        Members::CreateService.new(@user, @group, valid_params).execute
      end

      assert_equal 'GroupMember', @group.group_members.find_by(user_id: @user.id).type
    end

    test 'create project member with valid params' do
      user = users(:steve_doe)
      valid_params = { user:,
                       access_level: Member::AccessLevel::OWNER }

      assert_difference -> { Members::ProjectMember.count } => 1 do
        Members::CreateService.new(@user, @project_namespace, valid_params).execute
      end

      assert_equal 'ProjectMember', @project_namespace.project_members.find_by(user_id: @user.id).type
    end

    test 'create group member with invalid params' do
      invalid_params = { user: nil,
                         access_level: Member::AccessLevel::OWNER }

      assert_no_difference('Members::GroupMember.count') do
        Members::CreateService.new(@user, @group, invalid_params).execute
      end
    end

    test 'create project member with invalid params' do
      invalid_params = { user: @user,
                         access_level: nil }

      assert_no_difference('Members::ProjectMember.count') do
        Members::CreateService.new(@user, @project_namespace, invalid_params).execute
      end
    end

    test 'create group member with valid params but no permissions in namespace' do
      user = users(:steve_doe)
      valid_params = { user: users(:michelle_doe),
                       access_level: Member::AccessLevel::OWNER }

      assert_no_difference('Members::GroupMember.count') do
        Members::CreateService.new(user, @group, valid_params).execute
      end
    end
  end
end
