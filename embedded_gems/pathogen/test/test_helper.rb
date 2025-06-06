# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/mock'
require 'view_component/test_helpers'
require 'active_support/core_ext/object/blank'
require_relative '../app/components/pathogen/form/form_helpers'

module ActiveSupport
  class TestCase
    # Add more helper methods to be used by all tests here...
  end
end

# Configure ViewComponent test helpers
class ViewComponent::TestCase
  include ViewComponent::TestHelpers
end
