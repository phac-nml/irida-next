# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/better_rails_system_tests'
require 'test_helpers/capybara_setup'
require 'test_helpers/cuprite_helpers'
require 'test_helpers/cuprite_setup'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  include BetterRailsSystemTests
  include CupriteHelpers
  include Warden::Test::Helpers
  Warden.test_mode!
end
