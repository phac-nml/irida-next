# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../test/dummy/config/environment'
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'
require 'view_component/test_helpers'
require 'capybara/rails'
require 'capybara/minitest'

# Set up Minitest reporters
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new,
  Minitest::Reporters::JUnitReporter.new('test/reports', false, single_file: true)
]

# Configure Capybara for system tests
class ActiveSupport::TestCase
  include ViewComponent::TestHelpers
  include Capybara::Minitest::Assertions
  
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
