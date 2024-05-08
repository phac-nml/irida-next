# frozen_string_literal: true

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Graphql', 'app/graphql'
    add_group 'View Components', 'app/components'
    add_group 'Policies', 'app/policies'
    add_filter 'lib/active_storage/service/'
    add_filter 'lib/azure/'
    add_filter '/test/'
    add_filter '/vendor/'
    enable_coverage :branch
    enable_coverage_for_eval
  end
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'action_policy/test_helper'
require 'test_helpers/array_helpers'

Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(color: true)]

module ActiveSupport
  class TestCase
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}" if ENV['COVERAGE'] == 'true'
      ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{worker}"
    end

    parallelize_teardown do |_worker|
      SimpleCov.result if ENV['COVERAGE'] == 'true'
      FileUtils.rm_rf(ActiveStorage::Blob.service.root)
      FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
    end

    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include Devise::Test::IntegrationHelpers
    include ActionPolicy::TestHelper
    include ArrayHelpers
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper
  end
end
