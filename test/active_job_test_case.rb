# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/active_job_test_helpers'

class ActiveJobTestCase < ActiveJob::TestCase
  include ActiveJobTestHelpers
end
