# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/axe_helpers'
require 'test_helpers/better_rails_system_tests'
require 'test_helpers/capybara_setup'
require 'test_helpers/cuprite_helpers'
require 'test_helpers/cuprite_setup'
require 'test_helpers/html5_helpers'
require 'action_dispatch/system_test_case'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  served_by host: 'rails-app', port: ENV['CAPYBARA_SERVER_PORT'] if ENV.key?('CAPYBARA_SERVER_PORT')
  driven_by :irida_next_cuprite

  include AxeHelpers
  include BetterRailsSystemTests
  include CupriteHelpers
  include HTML5Helpers
  include Warden::Test::Helpers
  Warden.test_mode!
end
