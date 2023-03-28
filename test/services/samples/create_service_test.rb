# frozen_string_literal: true

require 'test_helper'

module Samples
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'create sample with valid params' do
      valid_params = { name: 'new-project2-sample', description: 'first sample for project2', project: @project }

      assert_difference('Sample.count') do
        Samples::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create sample with invalid params' do
      invalid_params = { name: 'ne', description: '', project: nil }

      assert_no_difference('Project.count') do
        Samples::CreateService.new(@user, invalid_params).execute
      end
    end
  end
end
