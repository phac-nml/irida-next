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
  end
end
