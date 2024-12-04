# frozen_string_literal: true

require 'test_helper'

# This class serves as the base class for all system test cases in the application.
# It inherits from ActionDispatch::SystemTestCase and configures the test driver to use
# Selenium with headless Chrome and a screen size of 1400x1400.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
