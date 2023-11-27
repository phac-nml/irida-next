# frozen_string_literal: true

require 'test_helper'

module Samples
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample23)
    end

    test 'update sample with valid params' do
      valid_params = { name: 'new-sample3-name', description: 'new-sample3-description' }

      assert_changes -> { [@sample.name, @sample.description] }, to: %w[new-sample3-name new-sample3-description] do
        Samples::UpdateService.new(@sample, @user, valid_params).execute
      end
    end

    test 'update sample with invalid params' do
      invalid_params = { name: 'ns', description: 'new-sample3-description' }

      assert_no_changes -> { @sample } do
        Samples::UpdateService.new(@sample, @user, invalid_params).execute
      end
    end

    test 'update sample in project with valid params when member of a parent group with role < MAINTAINER' do
      user = users(:ryan_doe)
      sample = samples(:sample1)
      valid_params = { name: 'new-name-for-sample', description: 'New name sample for project1' }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::UpdateService.new(sample, user, valid_params).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :update_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: sample.project.name),
                   exception.result.message
    end

    test 'valid authorization to update sample' do
      valid_params = { name: 'new-sample3-name', description: 'new-sample3-description' }

      assert_authorized_to(:update_sample?, @sample.project, with: ProjectPolicy,
                                                             context: { user: @user }) do
        Samples::UpdateService.new(@sample, @user, valid_params).execute
      end
    end

    test 'project sample update changes logged using logidze' do
      @sample.create_logidze_snapshot!

      assert_equal 1, @sample.log_data.version
      assert_equal 1, @sample.log_data.size

      valid_params = { name: 'new-sample23-name', description: 'new-sample23-description' }

      assert_changes -> { [@sample.name, @sample.description] }, to: %w[new-sample23-name new-sample23-description] do
        Samples::UpdateService.new(@sample, @user, valid_params).execute
      end

      @sample.create_logidze_snapshot!

      assert_equal 2, @sample.log_data.version
      assert_equal 2, @sample.log_data.size

      assert_equal 'Project 3 Sample 23', @sample.at(version: 1).name
      assert_equal 'Sample 23 description.', @sample.at(version: 1).description

      assert_equal 'new-sample23-name', @sample.at(version: 2).name
      assert_equal 'new-sample23-description', @sample.at(version: 2).description
    end

    test 'project sample update changes logged using logidze switch version' do
      @sample.create_logidze_snapshot!

      assert_equal 1, @sample.log_data.version
      assert_equal 1, @sample.log_data.size

      valid_params = { name: 'new-sample23-name', description: 'new-sample23-description' }

      assert_changes -> { [@sample.name, @sample.description] }, to: %w[new-sample23-name new-sample23-description] do
        Samples::UpdateService.new(@sample, @user, valid_params).execute
      end

      @sample.create_logidze_snapshot!

      assert_equal 2, @sample.log_data.version
      assert_equal 2, @sample.log_data.size

      assert_equal 'Project 3 Sample 23', @sample.at(version: 1).name
      assert_equal 'Sample 23 description.', @sample.at(version: 1).description

      assert_equal 'new-sample23-name', @sample.at(version: 2).name
      assert_equal 'new-sample23-description', @sample.at(version: 2).description

      @sample.switch_to!(1)

      assert_equal 'Project 3 Sample 23', @sample.name
      assert_equal 'Sample 23 description.', @sample.description
    end
  end
end
