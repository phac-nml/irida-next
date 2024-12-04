# frozen_string_literal: true

# This file sets up the test environment for the Rails application.
# It ensures that the Rails environment is set to 'test' and requires
# the necessary files for running tests. It also configures the test
# suite to run tests in parallel and loads all fixtures for use in tests.
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
module ActiveSupport
  # This module provides support for parallelizing test cases and setting up fixtures.
  #
  # ActiveSupport::TestCase:
  # - parallelize(workers: :number_of_processors): Runs tests in parallel using the number of processors available.
  # - fixtures :all: Loads all fixtures in the test/fixtures/*.yml directory for all tests in alphabetical order.
  # - Additional helper methods can be added to be used by all tests.
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
