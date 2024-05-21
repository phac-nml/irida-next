# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/capybara_setup'
require 'test_helpers/cuprite_helpers'
require 'test_helpers/cuprite_setup'
require 'action_dispatch/system_testing/server'
ActionDispatch::SystemTesting::Server.silence_puma = true
require 'action_dispatch/system_test_case'

class ViewComponentSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :irida_next_cuprite

  include CupriteHelpers
end
