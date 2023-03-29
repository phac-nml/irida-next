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

      assert_changes -> { [@sample.name, @sample.description] }, to: %w[new-sample3-name new-sample3-description] do
        Samples::UpdateService.new(@sample, @user, valid_params).execute
      end
    end

    test 'update project with invalid params' do
      invalid_params = { name: 'ns', description: 'new-sample3-description' }

      assert_no_changes -> { @sample } do
        Samples::UpdateService.new(@sample, @user, invalid_params).execute
      end
    end
  end
end
