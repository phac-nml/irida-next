# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Graphql', 'app/graphql'
  add_group 'View Components', 'app/components'
  add_filter '/test/'
  add_filter '/vendor/'
  enable_coverage :branch
  enable_coverage_for_eval
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |_worker|
      SimpleCov.result
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include Devise::Test::IntegrationHelpers
  end
end
