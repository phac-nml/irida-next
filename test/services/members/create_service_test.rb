# frozen_string_literal: true

require 'test_helper'

module Members
  class CreateServiceTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
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

      assert_difference -> { Member.count } => 1 do
        Members::CreateService.new(@user, @group, valid_params).execute
      end
    end

    test 'create project member with valid params' do
      user = users(:steve_doe)
      valid_params = { user:,
                       access_level: Member::AccessLevel::OWNER }

      assert_difference -> { Member.count } => 1 do
        Members::CreateService.new(@user, @project_namespace, valid_params).execute
      end
    end

    test 'create group member with invalid params' do
      invalid_params = { user: nil,
                         access_level: Member::AccessLevel::OWNER }

      assert_no_difference('Member.count') do
        Members::CreateService.new(@user, @group, invalid_params).execute
      end
    end

    test 'create project member with invalid params' do
      invalid_params = { user: @user,
                         access_level: nil }

      assert_no_difference('Member.count') do
        Members::CreateService.new(@user, @project_namespace, invalid_params).execute
      end
    end

    test 'create group member with valid params but no permissions in namespace' do
      user = users(:steve_doe)
      valid_params = { user: users(:michelle_doe),
                       access_level: Member::AccessLevel::OWNER }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Members::CreateService.new(user, @group, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'create group member with valid params when member of a parent group with the OWNER role' do
      user = users(:michelle_doe)
      valid_params = { user: users(:ryan_doe),
                       access_level: Member::AccessLevel::OWNER }
      group = groups(:subgroup_one_group_three)

      assert_difference -> { Member.count } => 1 do
        Members::CreateService.new(user, group, valid_params).execute
      end
    end

    test 'create group member with valid params when member of a parent group with MAINTAINER role' do
      user = users(:micha_doe)
      valid_params = { user: users(:ryan_doe),
                       access_level: Member::AccessLevel::MAINTAINER }
      group = groups(:subgroup_one_group_three)

      assert_difference -> { Member.count } => 1 do
        Members::CreateService.new(user, group, valid_params).execute
      end
    end

    test 'create group member with valid params when member of a parent group with MAINTAINER role and group member
    has OWNER role' do
      user = users(:micha_doe)
      valid_params = { user: users(:ryan_doe),
                       access_level: Member::AccessLevel::OWNER }
      group = groups(:subgroup_one_group_three)

      assert_no_difference ['Member.count'] do
        Members::CreateService.new(user, group, valid_params).execute
      end
    end

    test 'create project member with valid params when member of a parent group with MAINTAINER role and project member
    has OWNER role' do
      project = projects(:project1)
      project_namespace = project.namespace
      user = users(:joan_doe)

      valid_params = { user: users(:steve_doe),
                       access_level: Member::AccessLevel::OWNER }

      assert_no_difference ['Member.count'] do
        Members::CreateService.new(user, project_namespace, valid_params).execute
      end
    end

    test 'valid authorization to create group member' do
      user = users(:steve_doe)
      group = groups(:subgroup1)
      valid_params = { user:, access_level: Member::AccessLevel::OWNER }

      assert_authorized_to(:manage?, group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Members::CreateService.new(@user, group, valid_params).execute
      end
    end

    test 'valid authorization to create project member' do
      user = users(:steve_doe)
      valid_params = { user:,
                       access_level: Member::AccessLevel::OWNER }

      assert_authorized_to(:manage?, @project_namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Members::CreateService.new(@user, @project_namespace, valid_params).execute
      end
    end
  end
end
