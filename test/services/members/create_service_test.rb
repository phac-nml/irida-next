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
      valid_params = { user: @user, namespace: @group,
                       access_level: Member::AccessLevel::OWNER,
                       type: 'GroupMember' }

      assert_difference -> { Members::GroupMember.count } => 1 do
        Members::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project member with valid params' do
      valid_params = { user: @user, namespace: @project_namespace,
                       access_level: Member::AccessLevel::OWNER,
                       type: 'ProjectMember' }

      assert_difference -> { Members::ProjectMember.count } => 1 do
        Members::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create group member with invalid params' do
      invalid_params = { user: nil, namespace: @group,
                         access_level: Member::AccessLevel::OWNER,
                         type: 'GroupMember' }

      assert_no_difference('Members::GroupMember.count') do
        Members::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create project member with invalid params' do
      invalid_params = { user: @user, namespace: @project_namespace,
                         access_level: nil,
                         type: 'ProjectMember' }

      assert_no_difference('Members::ProjectMember.count') do
        Members::CreateService.new(@user, invalid_params).execute
      end
    end
  end
end
