# frozen_string_literal: true

require 'test_helper'

class TimeAgoHelperTest < ActionView::TestCase
  include TimeAgoHelper
  include ViewHelper

  test 'time difference' do
    current_time = DateTime.new(2023, 1, 2)
    original_time = DateTime.new(2023, 1, 1)
    time_difference = time_ago(current_time, original_time)
    assert time_difference.include? 'January 01, 2023 00:00'
  end
end
