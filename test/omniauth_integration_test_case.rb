# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/omniauth_helpers'

class OmniauthIntegrationTestCase < ActionDispatch::IntegrationTest
  include OmniauthDeveloperHelper
  include OmniauthAzureHelper
  include OmniauthSamlHelper
end
