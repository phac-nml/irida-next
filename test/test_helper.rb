# frozen_string_literal: true

require 'simplecov'
require 'public_activity/testing'

module SimpleCov
  class SourceFile
    # override this function to silence warnings for erb files which report lines incorrectly
    def coverage_exceeding_source_warn
      return if filename.ends_with? '.erb'

      warn "Warning: coverage data provided by Coverage [#{coverage_data['lines'].size}] exceeds number of lines in #{filename} [#{src.size}]" # rubocop:disable Layout/LineLength
    end
  end
end

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

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'action_policy/test_helper'
require 'test_helpers/array_helpers'

module ActiveSupport
  class TestCase
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{worker}"

      Searchkick.index_suffix = worker

      # reindex models
      Sample.reindex

      # and disable callbacks
      Searchkick.disable_callbacks
    end

    parallelize_teardown do |_worker|
      SimpleCov.result
      FileUtils.rm_rf(ActiveStorage::Blob.service.root)
    end

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    Minitest.after_run do
      FileUtils.rm_rf(ActiveStorage::Blob.service.root)
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include Devise::Test::IntegrationHelpers
    include ActionPolicy::TestHelper
    include ArrayHelpers
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    PublicActivity.enabled = true
  end
end
