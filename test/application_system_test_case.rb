# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/axe_helpers'
require 'test_helpers/better_rails_system_tests'
require 'test_helpers/capybara_setup'
require 'test_helpers/playwright_setup'
require 'test_helpers/html5_helpers'
require 'action_dispatch/system_test_case'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :irida_next_playwright

  include AxeHelpers
  include BetterRailsSystemTests
  include HTML5Helpers
  include Warden::Test::Helpers
  Warden.test_mode!
end
