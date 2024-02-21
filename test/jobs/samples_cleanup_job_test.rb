# frozen_string_literal: true

require 'test_helper'

class SamplesCleanupJobTest < ActiveJob::TestCase
  def setup
    @sample = samples(:sample1)
  end

  test 'invalid argument string' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: '1')
    end
  end

  test 'invalid argument negative' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: -1)
    end
  end

  test 'invalid argument zero' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: 0)
    end
  end
end
