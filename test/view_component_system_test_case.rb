# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/capybara_setup'
require 'test_helpers/cuprite_helpers'
require 'test_helpers/cuprite_setup'

class ViewComponentSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :irida_next_cuprite

  include CupriteHelpers
end
