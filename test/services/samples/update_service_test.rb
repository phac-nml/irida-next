# frozen_string_literal: true

require 'test_helper'

module Samples
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:three)
    end

    test 'update sample with valid params' do
      valid_params = { name: 'new-sample3-name', description: 'new-sample3-description' }

      Samples::UpdateService.new(@sample, @user, valid_params).execute

      assert_equal 'new-sample3-name', @sample.reload.name
      assert_equal 'new-sample3-description', @sample.reload.description
    end

    test 'cupdate project with invalid params' do
      invalid_params = { name: 'ns', description: 'new-sample3-description' }

      Samples::UpdateService.new(@sample, @user, invalid_params).execute

      assert_not_equal 'ns', @sample.reload.name
      assert_not_equal 'new-sample3-description', @sample.reload.description
    end
  end
end
