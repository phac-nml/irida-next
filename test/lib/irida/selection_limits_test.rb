# frozen_string_literal: true

require 'test_helper'

module Irida
  class SelectionLimitsTest < ActiveSupport::TestCase
    test 'MAX_COUNT is 50_000' do
      assert_equal 50_000, SelectionLimits::MAX_COUNT
    end

    test 'exceeded? returns false at the limit' do
      assert_not SelectionLimits.exceeded?(50_000)
    end

    test 'exceeded? returns true above the limit' do
      assert SelectionLimits.exceeded?(50_001)
    end

    test 'error_message includes the limit' do
      assert_includes SelectionLimits.error_message, '50'
    end
  end
end
