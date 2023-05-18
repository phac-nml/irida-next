# frozen_string_literal: true

require 'test_helper'

module Samples
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'create sample with valid params' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2' }

      assert_difference -> { Sample.count } => 1 do
        Samples::CreateService.new(@user, @project, valid_params).execute
      end
    end

    test 'create sample with invalid params' do
      invalid_params = { name: 'ne', description: '' }

      assert_no_difference('Sample.count') do
        Samples::CreateService.new(@user, @project, invalid_params).execute
      end
    end

    test 'create sample with valid params but no namespace permissions' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2' }
      user = users(:michelle_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::CreateService.new(user, @project, valid_params).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.manage?', name: @project.name),
                   exception.result.message
    end

    test 'create sample in project with valid params when member of a parent group with the OWNER role' do
      user = users(:michelle_doe)
      project = projects(:project4)
      valid_params = { name: 'new-project4-sample', description: 'first sample for project4' }

      assert_difference -> { Sample.count } => 1 do
        Samples::CreateService.new(user, project, valid_params).execute
      end
    end

    test 'create sample in project with valid params when member of a parent group with MAINTAINER role' do
      user = users(:micha_doe)
      project = projects(:project4)
      valid_params = { name: 'new-project4-sample', description: 'first sample for project4' }

      assert_difference -> { Sample.count } => 1 do
        Samples::CreateService.new(user, project, valid_params).execute
      end
    end

    test 'create sample in project with valid params when member of a parent group with role < MAINTAINER' do
      user = users(:ryan_doe)
      project = projects(:project4)
      valid_params = { name: 'new-project4-sample', description: 'first sample for project4' }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::CreateService.new(user, project, valid_params).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :manage?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.manage?', name: project.name),
                   exception.result.message
    end

    test 'valid authorization to create sample' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2' }

      assert_authorized_to(:manage?, @project, with: ProjectPolicy,
                                               context: { user: @user }) do
        Samples::CreateService.new(@user, @project,
                                   valid_params).execute
      end
    end
  end
end
