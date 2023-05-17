# frozen_string_literal: true

require 'test_helper'

module Samples
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample23)
    end

    test 'destroy sample with correct permissions' do
      assert_difference -> { Sample.count } => -1 do
        Samples::DestroyService.new(@sample, @user).execute
      end
    end

    test 'destroy sample with incorrect permissions' do
      @user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(@sample, @user).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to destroy sample' do
      assert_authorized_to(:destroy?, @sample.project, with: ProjectPolicy,
                                                       context: { user: @user }) do
        Samples::DestroyService.new(@sample,
                                    @user).execute
      end
    end
  end
end
