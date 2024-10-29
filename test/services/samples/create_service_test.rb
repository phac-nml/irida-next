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
      assert_equal :create_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.create_sample?', name: @project.name),
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
      assert_equal :create_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.create_sample?', name: project.name),
                   exception.result.message
    end

    test 'valid authorization to create sample' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2' }

      assert_authorized_to(:create_sample?, @project, with: ProjectPolicy,
                                                      context: { user: @user }) do
        Samples::CreateService.new(@user, @project,
                                   valid_params).execute
      end
    end

    test 'create project sample logged using logidze' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2' }
      sample = Samples::CreateService.new(@user, @project, valid_params).execute

      sample.create_logidze_snapshot!

      assert_equal 1, sample.log_data.version
      assert_equal 1, sample.log_data.size
      assert_equal 'new-project2-sample', sample.at(version: 1).name
      assert_equal 'first sample for project2', sample.at(version: 1).description
    end

    test 'samples count updated after sample creation' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      group12 = groups(:group_twelve)
      subgroup12a = groups(:subgroup_twelve_a)
      subgroup12b = groups(:subgroup_twelve_b)
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      valid_params = { name: 'sample36', description: 'new sample for project31' }

      assert_equal(2, subgroup12aa.samples_count)
      assert_equal(3, subgroup12a.samples_count)
      assert_equal(1, subgroup12b.samples_count)
      assert_equal(4, group12.samples_count)

      assert_no_changes -> { subgroup12b.reload.samples_count } do
        Samples::CreateService.new(@user, project31, valid_params).execute
      end

      assert_equal(3, subgroup12aa.reload.samples_count)
      assert_equal(4, subgroup12a.reload.samples_count)
      assert_equal(5, group12.reload.samples_count)
    end
  end
end
