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
      assert_raises(ActionPolicy::Unauthorized) { Samples::DestroyService.new(@sample, @user).execute }
    end
  end
end
